const std = @import("std");

const getAttributes = @import("../../attributes.zig").getAttributes;
const StringLifetime = @import("../../lifetime.zig").StringLifetime;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;
const VisitStringReturn = @import("../../interfaces/visitor.zig").VisitStringReturn;

pub fn Visitor(comptime Enum: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitInt = visitInt,
                .visitString = visitString,
            },
        );

        const Value = Enum;

        fn visitInt(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
        ) Deserializer.Err!Value {
            _ = result_ally;
            _ = scratch_ally;

            @setEvalBranchQuota(10_000);

            const fields = std.meta.fields(Value);
            const attributes = comptime getAttributes(Value, Deserializer);
            var e = std.meta.intToEnum(Value, input) catch return error.InvalidValue;

            if (attributes) |attrs| {
                inline for (fields) |field| {
                    const tag_matches = e == @field(@TypeOf(e), field.name);

                    if (tag_matches) {
                        const attrs_exist = @hasField(@TypeOf(attrs), field.name);

                        if (attrs_exist) {
                            const attr = @field(attrs, field.name);

                            const skipped = @hasField(@TypeOf(attr), "skip") and attr.skip;
                            if (skipped) return error.InvalidValue;
                        }

                        break;
                    }
                }
            }

            return e;
        }

        fn visitString(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
            _: StringLifetime,
        ) Deserializer.Err!VisitStringReturn(Value) {
            _ = result_ally;
            _ = scratch_ally;

            @setEvalBranchQuota(10_000);

            const fields = std.meta.fields(Value);
            const attributes = comptime getAttributes(Value, Deserializer);

            inline for (fields) |field| {
                const attrs = comptime attrs: {
                    if (attributes) |attrs| {
                        if (@hasField(@TypeOf(attrs), field.name)) {
                            const attr = @field(attrs, field.name);
                            break :attrs @as(?@TypeOf(attr), attr);
                        }
                    }

                    break :attrs null;
                };

                comptime var name = field.name;

                comptime if (attrs) |a| {
                    const skipped = @hasField(@TypeOf(a), "skip") and a.skip;
                    if (skipped) continue;

                    const renamed = @hasField(@TypeOf(a), "rename");
                    if (renamed) name = a.rename;
                };

                const name_cmp = std.mem.eql(u8, name, input);
                const aliases_cmp = aliases_cmp: {
                    comptime var aliases = aliases: {
                        if (attrs) |a| {
                            const aliased = @hasField(@TypeOf(a), "aliases");
                            if (aliased) break :aliases a.aliases;
                        }

                        break :aliases_cmp false;
                    };

                    for (aliases) |a| {
                        if (std.mem.eql(u8, a, input)) {
                            break :aliases_cmp true;
                        }
                    }

                    break :aliases_cmp false;
                };

                if (name_cmp or aliases_cmp) {
                    var e = std.meta.stringToEnum(Value, field.name) orelse return error.UnknownVariant;
                    return .{ .value = e, .used = false };
                }
            }

            return error.UnknownVariant;
        }
    };
}
