const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime Union: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace getty.de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitUnion,
            undefined,
        );

        const Value = Union;

        fn visitUnion(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Error!Value {
            var variant = try ua.variant(allocator, []const u8);

            inline for (std.meta.fields(Value)) |f| {
                if (std.mem.eql(u8, f.name, variant)) {
                    const alloc = if (f.field_type == void) null else allocator;
                    return @unionInit(Value, f.name, try va.payload(alloc, f.field_type));
                }
            }

            return error.UnknownVariant;
        }
    };
}
