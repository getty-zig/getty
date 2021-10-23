const getty = @import("../../../lib.zig");

const Visitor = @This();
const impl = @"impl Visitor";

pub usingnamespace getty.de.Visitor(
    Visitor,
    impl.visitor.Value,
    impl.visitor.visitBool,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
);

const @"impl Visitor" = struct {
    pub const visitor = struct {
        pub const Value = bool;

        pub fn visitBool(self: Visitor, comptime Error: type, input: bool) Error!Value {
            _ = self;

            return input;
        }
    };
};
