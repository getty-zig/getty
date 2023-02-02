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

        fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            const fields = comptime std.meta.fields(Value);
            const attributes = comptime getAttributes(Value, Deserializer);

            var structure: Value = undefined;
            var seen = [_]bool{false} ** fields.len;

            errdefer {
                if (allocator) |alloc| {
                    inline for (fields) |field, i| {
                        if (!field.is_comptime and seen[i]) {
                            free(alloc, @field(structure, field.name));
                        }
                    }
                }
            }

            const ignore_unknown_fields = comptime blk: {
                if (attributes) |attrs| {
                    if (@hasField(@TypeOf(attrs), "Container")) {
                        const attr = attrs.Container;

                        if (@hasField(@TypeOf(attr), "ignore_unknown_fields") and attr.ignore_unknown_fields) {
                            break :blk true;
                        }
                    }
                }

                break :blk false;
            };

            key_loop: while (try map.nextKey(allocator, []const u8)) |key| {
                const key_is_allocated = map.isKeyAllocated(@TypeOf(key));

                if (key_is_allocated and allocator == null) {
                    return error.MissingAllocator;
                }

                defer if (key_is_allocated) {
                    std.debug.assert(allocator != null);
                    free(allocator.?, key);
                };

                var found = false;

                // Check to see if the key matches any field in Struct.
                //
                // If there are no matches, found will remain false and an
                // error will be returned immediately after this loop.
                inline for (fields) |field, i| {
                    // The name of the field to be deserialized.
                    var name = field.name;

                    // Process 'rename' attribute.
                    if (attributes) |attrs| {
                        if (@hasField(@TypeOf(attrs), field.name)) {
                            const attr = @field(attrs, field.name);

                            if (@hasField(@TypeOf(attr), "rename")) {
                                name = attr.rename;
                            }
                        }
                    }

                    // Deserialize field.
                    if (std.mem.eql(u8, name, key)) {
                        // Return an error for duplicate fields.
                        if (seen[i]) {
                            return error.DuplicateField;
                        }

                        // Process 'skip' attribute.
                        if (attributes) |attrs| {
                            if (@hasField(@TypeOf(attrs), field.name)) {
                                const attr = @field(attrs, field.name);

                                if (@hasField(@TypeOf(attr), "skip") and attr.skip) {
                                    // Skip value, but check its validity.
                                    _ = try map.nextValue(allocator, field.type);

                                    // Move on to next key.
                                    continue :key_loop;
                                }
                            }
                        }

                        // Deserialize and assign value to field.
                        switch (field.is_comptime) {
                            false => @field(structure, field.name) = try map.nextValue(allocator, field.type),
                            true => @compileError("TODO"),
                        }

                        seen[i] = true;
                        found = true;

                        break;
                    }
                }

                if (!found) {
                    switch (ignore_unknown_fields) {
                        true => _ = try map.nextValue(allocator, Ignored),
                        false => return error.UnknownField,
                    }
                }
            }

            // Set any remaining fields with default values that haven't been
            // assigned to yet.
            inline for (fields) |field, i| {
                if (!seen[i]) {
                    if (field.default_value) |default_ptr| {
                        if (!field.is_comptime) {
                            const aligned_default_ptr = @alignCast(@alignOf(field.type), default_ptr);
                            const default_value = @ptrCast(*const field.type, aligned_default_ptr).*;
                            @field(structure, field.name) = default_value;
                        }
                    } else {
                        return error.MissingField;
                    }
                }
            }

            return structure;
        }
    };
}
