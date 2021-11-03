const std = @import("std");

const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Struct: type) type {
    return struct {
        allocator: ?*std.mem.Allocator = null,

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
                var seen: usize = 0;
                var map: Value = undefined;

                errdefer {
                    if (self.allocator) |allocator| {
                        inline for (std.meta.fields(Value)) |field, i| {
                            if (i < seen) {
                                getty.de.free(allocator, @field(map, field.name));
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
    };
}
