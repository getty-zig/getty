const std = @import("std");

const de = @import("../../lib.zig").de;

pub const VoidVisitor = struct {
    const Self = @This();

    /// Implements `getty.de.Visitor`.
    pub fn visitor(self: *Self) V {
        return .{ .context = self };
    }

    const V = de.Visitor(
        *Self,
        _V.Value,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        _V.visitVoid,
    );

    const _V = struct {
        const Value = void;

        fn visitVoid(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            return {};
        }
    };
};

pub const BoolVisitor = struct {
    const Self = @This();

    /// Implements `getty.de.Visitor`.
    pub fn visitor(self: *Self) V {
        return .{ .context = self };
    }

    const V = de.Visitor(
        *Self,
        _V.Value,
        _V.visitBool,
        _V.visitFloat,
        _V.visitInt,
        _V.visitMap,
        _V.visitNull,
        _V.visitSequence,
        _V.visitSome,
        _V.visitString,
        _V.visitVariant,
        _V.visitVoid,
    );

    const _V = struct {
        const Value = bool;

        fn visitBool(self: *Self, comptime Error: type, input: bool) Error!Value {
            _ = self;

            return input;
        }

        fn visitInt(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitFloat(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitMap(self: *Self, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            _ = self;

            @panic("Unsupported");
        }

        fn visitNull(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            @panic("Unsupported");
        }

        fn visitSequence(self: *Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
            _ = self;

            @panic("Unsupported");
        }

        fn visitSome(self: *Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            _ = self;

            @panic("Unsupported");
        }

        fn visitString(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitVariant(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitVoid(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            @panic("Unsupported");
        }
    };
};

pub fn FloatVisitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub fn visitor(self: *Self) V {
            return .{ .context = self };
        }

        const V = de.Visitor(
            *Self,
            _V.Value,
            undefined,
            _V.visitFloat,
            _V.visitInt,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );

        const _V = struct {
            const Value = T;

            fn visitFloat(_: *Self, comptime Error: type, input: anytype) Error!Value {
                comptime std.debug.assert(@typeInfo(@TypeOf(input)) == .Float);

                return @floatCast(T, value);
            }

            fn visitInt(_: *Self, comptime Error: type, input: anytype) Error!Value {
                comptime std.debug.assert(@typeInfo(@TypeOf(input)) == .Int);

                return @intToFloat(T, value);
            }
        };
    };
}

pub fn IntVisitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub fn visitor(self: *Self) V {
            return .{ .context = self };
        }

        const V = de.Visitor(
            *Self,
            _V.Value,
            undefined,
            _V.visitFloat,
            _V.visitInt,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );

        const _V = struct {
            const Value = T;

            fn visitFloat(_: *Self, comptime Error: type, input: anytype) Error!Value {
                comptime std.debug.assert(@typeInfo(@TypeOf(input)) == .Float);

                return @floatToInt(T, value);
            }

            fn visitInt(_: *Self, comptime Error: type, input: anytype) Error!Value {
                comptime std.debug.assert(@typeInfo(@TypeOf(input)) == .Int);

                return @intCast(T, value);
            }
        };
    };
}
