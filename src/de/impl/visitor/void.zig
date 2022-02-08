const getty = @import("../../../lib.zig");
const std = @import("std");

const Visitor = @This();
const impl = @"impl Visitor";

pub usingnamespace getty.de.Visitor(
    Visitor,
    impl.visitor.Value,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    impl.visitor.visitVoid,
);

const @"impl Visitor" = struct {
    const Self = Visitor;

    pub const visitor = struct {
        pub const Value = void;

        pub fn visitVoid(_: Visitor, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            return {};
        }
    };
};
