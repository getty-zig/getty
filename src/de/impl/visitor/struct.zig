const std = @import("std");

const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Value: type) type {
    return struct {
        allocator: ?*std.mem.Allocator = null,

        const Self = @This();

        /// Implements `getty.de.Visitor`.
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
        );

        fn visitMap(self: Self, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            var seen: usize = 0;
            var map: Value = undefined;
            errdefer {
                inline for (std.meta.fields(Value)) |field, i| {
                    if (i < seen) {
                        if (self.allocator) |allocator| {
                            getty.free(allocator, @field(map, field.name));
                        }
                    }
                }
            }

            inline for (std.meta.fields(Value)) |field| {
                if (try mapAccess.nextKey([]const u8)) |key| {
                    if (!std.mem.eql(u8, field.name, key)) {
                        return error.MissingField;
                    }

                    @field(map, field.name) = try mapAccess.nextValue(field.field_type);
                    seen += 1;
                }
            }

            if (try mapAccess.nextKey([]const u8)) |_| {
                return error.UnknownField;
            }

            return map;
        }
    };
}
