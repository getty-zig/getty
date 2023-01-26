const std = @import("std");

const getAttributes = @import("../../attributes.zig").getAttributes;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime Union: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitUnion = visitUnion },
        );

        const Value = Union;

        fn visitUnion(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Error!Value {
            const attributes = comptime getAttributes(Value, Deserializer);

            var variant = try ua.variant(allocator, []const u8);

            inline for (std.meta.fields(Value)) |f| {
                comptime var name = f.name;

                // Process "rename" attribute.
                if (attributes) |attrs| {
                    if (@hasField(@TypeOf(attrs), f.name)) {
                        const attr = @field(attrs, f.name);

                        if (@hasField(@TypeOf(attr), "rename")) {
                            name = attr.rename;
                        }
                    }
                }

                if (std.mem.eql(u8, name, variant)) {
                    // Process "skip" attribute.
                    if (attributes) |attrs| {
                        if (@hasField(@TypeOf(attrs), f.name)) {
                            const attr = @field(attrs, f.name);

                            if (@hasField(@TypeOf(attr), "skip") and attr.skip) {
                                return error.UnknownVariant;
                            }
                        }
                    }

                    return @unionInit(Value, f.name, try va.payload(allocator, f.type));
                }
            }

            return error.UnknownVariant;
        }
    };
}
