const std = @import("std");

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

        fn visitMap(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Err!Value {
            @setEvalBranchQuota(10_000);

            const fields = comptime std.meta.fields(Value);
            const attributes = comptime getAttributes(Value, Deserializer);

            var structure: Value = undefined;
            var seen = [_]bool{false} ** fields.len;

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
                defer switch (map.keyLifetime()) {
                    .heap => ally.free(key),
                    .managed => {},
                };

                // Indicates whether or not key matches any field in the struct.
                var found = false;

                inline for (fields, 0..) |field, i| {
                    const attrs = comptime attrs: {
                        if (attributes) |attrs| {
                            if (@hasField(@TypeOf(attrs), field.name)) {
                                const attr = @field(attrs, field.name);
                                break :attrs @as(?@TypeOf(attr), attr);
                            }
                        }

                        break :attrs null;
                    };

                    // The name that will be used to compare key against.
                    //
                    // Initially, name is set to field's name. But field has
                    // the "rename" attribute set, name is set to the
                    // attribute's value.
                    comptime var name = name: {
                        var name = field.name;

                        if (attrs) |a| {
                            const renamed = @hasField(@TypeOf(a), "rename");
                            if (renamed) name = a.rename;
                        }

                        break :name name;
                    };

                    // If key matches field's name, rename attribute, or
                    // any of its aliases, deserialize the field.
                    const name_cmp = std.mem.eql(u8, name, key);
                    const aliases_cmp = aliases_cmp: {
                        comptime var aliases = aliases: {
                            if (attrs) |a| {
                                const aliased = @hasField(@TypeOf(a), "aliases");
                                if (aliased) break :aliases a.aliases;
                            }

                            break :aliases_cmp false;
                        };

                        for (aliases) |a| {
                            if (std.mem.eql(u8, a, key)) {
                                break :aliases_cmp true;
                            }
                        }

                        break :aliases_cmp false;
                    };

                    if (name_cmp or aliases_cmp) {
                        if (field.is_comptime) {
                            @compileError("TODO: DESERIALIZATION OF COMPTIME FIELD");
                        }

                        // If field has already been deserialized, return an
                        // error.
                        if (seen[i]) {
                            return error.DuplicateField;
                        }

                        const value = try map.nextValue(ally, field.type);

                        // Do not assign value to field if the "skip" attribute is
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
