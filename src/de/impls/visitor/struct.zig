const std = @import("std");

const free = @import("../../free.zig").free;
const getAttributes = @import("../../attributes.zig").getAttributes;
const Ignored = @import("../../impls/seed/ignored.zig").Ignored;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime Struct: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitMap = visitMap },
        );

        const Value = Struct;

        fn visitMap(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            @setEvalBranchQuota(10_000);

            const fields = comptime std.meta.fields(Value);
            const attributes = comptime getAttributes(Value, Deserializer);

            var structure: Value = undefined;
            var seen = [_]bool{false} ** fields.len;

            errdefer {
                if (ally) |a| {
                    inline for (fields, 0..) |field, i| {
                        if (!field.is_comptime and seen[i]) {
                            free(a, Deserializer, @field(structure, field.name));
                        }
                    }
                }
            }

            // Indicates whether or not unknown fields should be ignored.
            const ignore_unknown_fields = comptime blk: {
                if (attributes) |attrs| {
                    if (@hasField(@TypeOf(attrs), "Container")) {
                        const attr = attrs.Container;
                        const ignore = @hasField(@TypeOf(attr), "ignore_unknown_fields") and attr.ignore_unknown_fields;

                        if (ignore) break :blk true;
                    }
                }

                break :blk false;
            };

            key_loop: while (try map.nextKey(ally, []const u8)) |key| {
                // If key is allocated, free it at the end of this loop.
                //
                // key won't ever be part of the final value returned by the
                // visitor, so there's never a reason to keep it around.
                const key_is_allocated = map.isKeyAllocated(@TypeOf(key));

                if (key_is_allocated and ally == null) {
                    return error.MissingAllocator;
                }

                defer if (key_is_allocated) {
                    std.debug.assert(ally != null);
                    free(ally.?, Deserializer, key);
                };

                // Indicates whether or not key matches any field in the struct.
                var found = false;

                inline for (fields, 0..) |field, i| {
                    const attrs = comptime blk: {
                        if (attributes) |attrs| {
                            if (@hasField(@TypeOf(attrs), field.name)) {
                                const a = @field(attrs, field.name);
                                const A = @TypeOf(a);

                                break :blk @as(?A, a);
                            }
                        }

                        break :blk null;
                    };

                    // The name that will be used to compare key against.
                    //
                    // Initially, name is set to field's name. But field has
                    // the "rename" attribute set, name is set to the
                    // attribute's value.
                    var name = blk: {
                        var n = field.name;

                        if (attrs) |a| {
                            const renamed = @hasField(@TypeOf(a), "rename");
                            if (renamed) n = a.rename;
                        }

                        break :blk n;
                    };

                    // If key matches field's name or its rename attribute,
                    // deserialize the field.
                    if (std.mem.eql(u8, name, key)) {
                        if (field.is_comptime) {
                            @compileError("TODO: DESERIALIZATION OF COMPTIME FIELD");
                        }

                        // If field has already been deserialized, return an
                        // error.
                        if (seen[i]) {
                            return error.DuplicateField;
                        }

                        const value = try map.nextValue(ally, field.type);

                        // Do assign value to field if the "skip" attribute is
                        // set.
                        //
                        // Note that we still deserialize a value and check its
                        // validity (e.g., its type is correct), we just don't
                        // assign it to field.
                        if (attrs) |a| {
                            const skipped = @hasField(@TypeOf(a), "skip") and a.skip;
                            if (skipped) continue :key_loop;
                        }

                        // Deserialize and assign value to field.
                        @field(structure, field.name) = value;

                        seen[i] = true;
                        found = true;

                        break;
                    }
                }

                // Handle any keys that didn't match any fields in the struct.
                //
                // If the "ignore_unknown_fields" attribute is set, we'll
                // deserialize and discard its corresponding value. Note that
                // unlike with the "skip" attribute, the validity of an unknown
                // field is not checked.
                if (!found) {
                    switch (ignore_unknown_fields) {
                        true => _ = try map.nextValue(ally, Ignored),
                        false => return error.UnknownField,
                    }
                }
            }

            // Process any remaining, unassigned fields.
            inline for (fields, 0..) |field, i| {
                if (!seen[i]) blk: {
                    // Assign to field the value of the "default" attribute, if
                    // it is set.
                    if (attributes) |attrs| {
                        if (@hasField(@TypeOf(attrs), field.name)) {
                            const attr = @field(attrs, field.name);

                            if (@hasField(@TypeOf(attr), "default")) {
                                if (!field.is_comptime) {
                                    @field(structure, field.name) = attr.default;

                                    break :blk;
                                }
                            }
                        }
                    }

                    // Assign to field its default value if it exists and the
                    // "default" attribute is not set.
                    if (field.default_value) |default_ptr| {
                        if (!field.is_comptime) {
                            const default_value = @as(*const field.type, @ptrCast(@alignCast(default_ptr))).*;
                            @field(structure, field.name) = default_value;

                            break :blk;
                        }
                    }

                    // The field has not been assigned a value and does not
                    // have any default value, so return an error.
                    return error.MissingField;
                }
            }

            return structure;
        }
    };
}
