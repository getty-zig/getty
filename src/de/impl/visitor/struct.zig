const std = @import("std");

const interface = @import("../../interface.zig");

pub fn Visitor(comptime Value: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace interface.Visitor(
            *Self,
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

        fn visitMap(self: *Self, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            _ = self;

            var map: Value = undefined;

            inline for (std.meta.fields(Value)) |field| {
                if (try mapAccess.nextKey([]const u8)) |key| {
                    if (!std.mem.eql(u8, field.name, key)) {
                        @panic("incorrect key");
                    }

                    @field(map, field.name) = try mapAccess.nextValue(field.field_type);
                }
            }

            if (try mapAccess.nextKey([]const u8)) |_| {
                @panic("expected end of map, found key");
            }

            return map;
        }
    };
}
