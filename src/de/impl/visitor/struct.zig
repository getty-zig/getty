const std = @import("std");

const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Struct: type) type {
    return struct {
        allocator: ?std.mem.Allocator = null,

        const Self = @This();
        const impl = @"impl Visitor"(Struct);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.Value,
            undefined,
            undefined,
            undefined,
            undefined,
            impl.visitor.visitMap,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );
    };
}

fn @"impl Visitor"(comptime Struct: type) type {
    const Self = Visitor(Struct);

    return struct {
        pub const visitor = struct {
            pub const Value = Struct;

            pub fn visitMap(self: Self, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
                const fields = std.meta.fields(Value);

                var map: Value = undefined;
                var seen = [_]bool{false} ** fields.len;

                errdefer {
                    if (self.allocator) |allocator| {
                        inline for (fields) |field, i| {
                            if (!field.is_comptime and seen[i]) {
                                getty.de.free(allocator, @field(map, field.name));
                            }
                        }
                    }
                }

                while (try mapAccess.nextKey([]const u8)) |key| {
                    defer self.allocator.?.free(key);

                    var found = false;

                    inline for (fields) |field, i| {
                        if (std.mem.eql(u8, field.name, key)) {
                            if (seen[i]) {
                                return error.DuplicateField;
                            }

                            switch (field.is_comptime) {
                                true => @compileError("TODO"),
                                false => @field(map, field.name) = try mapAccess.nextValue(field.field_type),
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
                                @field(map, field.name) = default;
                            }
                        } else {
                            return error.MissingField;
                        }
                    }
                }

                return map;
            }
        };
    };
}
