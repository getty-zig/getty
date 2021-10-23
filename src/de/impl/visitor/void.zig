const getty = @import("../../../lib.zig");

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

        pub fn visitVoid(self: Visitor, comptime Error: type) Error!Value {
            _ = self;

            return {};
        }
    };
};
