const getty = @import("../../../lib.zig");
const std = @import("std");

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

            pub fn visitEnum(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                return input;
            }

            pub fn visitInt(_: Self, _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                return std.meta.intToEnum(Value, input) catch unreachable;
            }

            pub fn visitString(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                defer getty.de.free(allocator.?, input);
                return std.meta.stringToEnum(Value, input) orelse return error.UnknownVariant;
            }
        };
    };
}
