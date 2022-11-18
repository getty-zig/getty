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
            const fields = std.meta.fields(Value);

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

            while (try map.nextKey(allocator, []const u8)) |key| {
                var found = false;

                inline for (fields) |field, i| {
                    if (std.mem.eql(u8, field.name, key)) {
                        if (seen[i]) {
                            return error.DuplicateField;
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

            inline for (fields) |field, i| {
                if (!seen[i]) {
                    if (field.default_value) |default_ptr| {
                        if (!field.is_comptime) {
                            @field(structure, field.name) = @ptrCast(*const field.field_type, default_ptr).*;
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
