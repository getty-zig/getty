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

        fn visitUnion(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Err!Value {
            @setEvalBranchQuota(10_000);

            const attributes = comptime getAttributes(Value, Deserializer);

            var variant = try ua.variant(ally, []const u8);

            inline for (std.meta.fields(Value)) |f| {
                const attrs = comptime attrs: {
                    if (attributes) |attrs| {
                        if (@hasField(@TypeOf(attrs), f.name)) {
                            const attr = @field(attrs, f.name);
                            break :attrs @as(?@TypeOf(attr), attr);
                        }
                    }

                    break :attrs null;
                };

                comptime var name = name: {
                    var name = f.name;

                    if (attrs) |a| {
                        const renamed = @hasField(@TypeOf(a), "rename");
                        if (renamed) name = a.rename;
                    }

                    break :name name;
                };

                // If key matches field's name, rename attribute, or
                // any of its aliases, deserialize the field.
                const name_cmp = std.mem.eql(u8, name, variant);
                const aliases_cmp = aliases_cmp: {
                    var aliases = aliases: {
                        if (attrs) |a| {
                            const aliased = @hasField(@TypeOf(a), "aliases");
                            if (aliased) break :aliases a.aliases;
                        }

                        break :aliases_cmp false;
                    };

                    for (aliases) |a| {
                        if (std.mem.eql(u8, a, variant)) {
                            break :aliases_cmp true;
                        }
                    }

                    break :aliases_cmp false;
                };

                if (name_cmp or aliases_cmp) {
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
