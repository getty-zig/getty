const std = @import("std");

const de = @import("../../../de.zig").de;

pub fn Visitor(comptime Struct: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.Visitor(
            Self,
            Value,
            .{ .visitMap = visitMap },
        );

        const Value = Struct;

        fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            const fields = comptime std.meta.fields(Value);
            const attributes = comptime de.getAttributes(Value, Deserializer);

            var structure: Value = undefined;
            var seen = [_]bool{false} ** fields.len;

            errdefer {
                if (allocator) |alloc| {
                    inline for (fields) |field, i| {
                        if (!field.is_comptime and seen[i]) {
                            de.free(alloc, @field(structure, field.name));
                        }
                    }
                }
            }

            key_loop: while (try map.nextKey(allocator, []const u8)) |key| {
                var found = false;

                // Check to see if the key matches any field in Struct.
                //
                // If there are no matches, found will remain false and an
                // error will be returned immediately after this loop.
                inline for (fields) |field, i| {
                    // The name of the field to be deserialized.
                    var name = key;

                    // Process 'rename' attribute.
                    if (attributes) |attrs| {
                        if (@hasField(@TypeOf(attrs), field.name)) {
                            const attr = @field(attrs, field.name);

                            if (@hasField(@TypeOf(attr), "rename") and std.mem.eql(u8, attr.rename, key)) {
                                name = field.name;
                            }
                        }
                    }

                    // Deserialize field.
                    if (std.mem.eql(u8, field.name, name)) {
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
                                    _ = try map.nextValue(allocator, field.field_type);

                                    // Move on to next key.
                                    continue :key_loop;
                                }
                            }
                        }

                        switch (field.is_comptime) {
                            true => @compileError("TODO"),
                            false => @field(structure, field.name) = try map.nextValue(allocator, field.field_type),
                        }

                        seen[i] = true;
                        found = true;

                        break;
                    }
                }

                if (!found) {
                    return error.UnknownField;
                }
            }

            // Set any remaining fields with default values that haven't been
            // assigned to yet.
            inline for (fields) |field, i| {
                if (!seen[i]) {
                    if (field.default_value) |default_ptr| {
                        if (!field.is_comptime) {
                            const aligned_default_ptr = @alignCast(@alignOf(field.field_type), default_ptr);
                            const default_value = @ptrCast(*const field.field_type, aligned_default_ptr).*;
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
