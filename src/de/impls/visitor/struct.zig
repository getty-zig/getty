const std = @import("std");

const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Struct: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace getty.de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            visitMap,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
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
                            getty.de.free(alloc, @field(structure, field.name));
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
                    if (field.default_value) |default| {
                        if (!field.is_comptime) {
                            @field(structure, field.name) = default;
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
