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
                .visitEnum = visitEnum,
                .visitInt = visitInt,
                .visitString = visitString,
            },
        );

        const Value = Enum;

        fn visitEnum(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            return try visitString(@tagName(input));
        }

        fn visitInt(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            const fields = std.meta.fields(Value);
            const attributes = comptime getAttributes(Value, Deserializer);
            const result = std.meta.intToEnum(Value, input) catch return error.InvalidValue;

            inline for (fields) |field| {
                if (std.meta.isTag(result, field.name)) {
                    if (attributes) |attrs| {
                        if (@hasField(@TypeOf(attrs), field.name)) {
                            const attr = @field(attrs, field.name);
                            const skipped = @hasField(@TypeOf(attr), "skip") and attr.skip;
                            if (skipped) return error.InvalidValue;
                        }
                    }
                    break;
                }
            }

            return result;
        }

        fn visitString(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            const fields = std.meta.fields(Value);
            const attributes = comptime getAttributes(Value, Deserializer);

            inline for (fields) |field| {
                comptime var name = field.name;

                if (attributes) |attrs| {
                    if (@hasField(@TypeOf(attrs), field.name)) {
                        const attr = @field(attrs, field.name);

                        const skipped = @hasField(@TypeOf(attr), "skip") and attr.skip;
                        if (skipped) continue;

                        const renamed = @hasField(@TypeOf(attr), "rename");
                        if (renamed) {
                            name = attr.rename;
                        }
                    }
                }

                if (std.mem.eql(u8, name, input)) {
                    return std.meta.stringToEnum(Value, field.name) orelse return error.UnknownVariant;
                }
            }

            return error.UnknownVariant;
        }
    };
}
