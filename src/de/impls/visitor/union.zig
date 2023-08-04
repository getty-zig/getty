const std = @import("std");

const free = @import("../../free.zig").free;
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

        fn visitUnion(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Error!Value {
            @setEvalBranchQuota(10_000);

            const attributes = comptime getAttributes(Value, Deserializer);

            var variant = try ua.variant(ally, []const u8);
            const variant_is_allocated = ua.isVariantAllocated(@TypeOf(variant));

            if (variant_is_allocated and ally == null) {
                return error.MissingAllocator;
            }

            defer if (variant_is_allocated) {
                std.debug.assert(ally != null);
                free(ally.?, Deserializer, variant);
            };

            inline for (std.meta.fields(Value)) |f| {
                const attrs = comptime blk: {
                    if (attributes) |attrs| {
                        if (@hasField(@TypeOf(attrs), f.name)) {
                            const a = @field(attrs, f.name);
                            const A = @TypeOf(a);

                            break :blk @as(?A, a);
                        }
                    }

                    break :blk null;
                };

                comptime var name = f.name;

                if (attrs) |a| {
                    const renamed = @hasField(@TypeOf(a), "rename");
                    if (renamed) name = a.rename;
                }

                if (std.mem.eql(u8, name, variant)) {
                    if (attrs) |a| {
                        const skipped = @hasField(@TypeOf(a), "skip") and a.skip;
                        if (skipped) return error.UnknownVariant;
                    }

                    return @unionInit(Value, f.name, try va.payload(ally, f.type));
                }
            }

            return error.UnknownVariant;
        }
    };
}
