const std = @import("std");

const getAttributes = @import("../../attributes.zig").getAttributes;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

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

        fn visitInt(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            @setEvalBranchQuota(10_000);

            const fields = std.meta.fields(Value);
            const attributes = comptime getAttributes(Value, Deserializer);
            const result = std.meta.intToEnum(Value, input) catch return error.InvalidValue;

            if (attributes) |attrs| {
                inline for (fields) |field| {
                    const tag_matches = result == @field(@TypeOf(result), field.name);

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

            return result;
        }

        fn visitString(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            @setEvalBranchQuota(10_000);

            const fields = std.meta.fields(Value);
            const attributes = comptime getAttributes(Value, Deserializer);

            inline for (fields) |field| {
                comptime var name = field.name;

                if (attributes) |attrs| {
                    const attrs_exist = @hasField(@TypeOf(attrs), field.name);

                    if (attrs_exist) {
                        const attr = @field(attrs, field.name);

                        const skipped = @hasField(@TypeOf(attr), "skip") and attr.skip;
                        if (skipped) continue;

                        const renamed = @hasField(@TypeOf(attr), "rename");
                        if (renamed) name = attr.rename;
                    }
                }

                if (std.mem.eql(u8, name, input)) {
                    return std.meta.stringToEnum(Value, field.name) orelse error.UnknownVariant;
                }
            }

            return error.UnknownVariant;
        }
    };
}
