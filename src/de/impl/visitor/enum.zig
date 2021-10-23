const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Enum: type) type {
    return struct {
        const Self = @This();
        const impl = @"impl Visitor"(Enum);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.Value,
            undefined,
            impl.visitor.visitEnum,
            undefined,
            impl.visitor.visitInt,
            undefined,
            undefined,
            undefined,
            impl.visitor.visitString,
            undefined,
            undefined,
        );
    };
}

fn @"impl Visitor"(comptime Enum: type) type {
    const Self = Visitor(Enum);

    return struct {
        pub const visitor = struct {
            pub const Value = Enum;

            pub fn visitEnum(self: Self, comptime Error: type, input: anytype) Error!Value {
                _ = self;

                return input;
            }

            pub fn visitInt(self: Self, comptime Error: type, input: anytype) Error!Value {
                _ = self;

                return std.meta.intToEnum(Value, input) catch unreachable;
            }

            pub fn visitString(self: Self, comptime Error: type, input: anytype) Error!Value {
                _ = self;

                return std.meta.stringToEnum(Value, input) orelse return error.UnknownVariant;
            }
        };
    };
}
