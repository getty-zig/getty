const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const assert = std.debug.assert;

pub fn Visitor(
    comptime Context: type,
    comptime Value: type,
    comptime visitBool: @TypeOf(struct {
        fn f(self: Context, comptime Error: type, input: bool) Error!Value {
            _ = self;
            _ = input;

            unreachable;
        }
    }.f),
    comptime visitEnum: @TypeOf(struct {
        fn f(self: Context, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            unreachable;
        }
    }.f),
    comptime visitFloat: @TypeOf(struct {
        fn f(self: Context, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            unreachable;
        }
    }.f),
    comptime visitInt: @TypeOf(struct {
        fn f(self: Context, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            unreachable;
        }
    }.f),
    comptime visitMap: @TypeOf(struct {
        fn f(self: Context, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            _ = self;
            _ = mapAccess;

            unreachable;
        }
    }.f),
    comptime visitNull: @TypeOf(struct {
        fn f(self: Context, comptime Error: type) Error!Value {
            _ = self;

            unreachable;
        }
    }.f),
    comptime visitSequence: @TypeOf(struct {
        fn f(self: Context, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
            _ = self;
            _ = sequenceAccess;

            unreachable;
        }
    }.f),
    comptime visitString: @TypeOf(struct {
        fn f(self: Context, comptime E: type, input: anytype) E!Value {
            _ = self;
            _ = input;

            unreachable;
        }
    }.f),
    comptime visitSome: @TypeOf(struct {
        fn f(self: Context, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            _ = self;

            unreachable;
        }
    }.f),
    comptime visitVoid: @TypeOf(struct {
        fn f(self: Context, comptime Error: type) Error!Value {
            _ = self;

            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.Visitor" = struct {
            context: Context,

            const Self = @This();

            pub const Value = Value;

            pub fn visitBool(self: Self, comptime Error: type, input: bool) Error!Value {
                return try visitBool(self.context, Error, input);
            }

            pub fn visitEnum(self: Self, comptime Error: type, input: anytype) Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Enum, .EnumLiteral => {},
                        else => @compileError("expected enum or enum literal, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitEnum(self.context, Error, input);
            }

            pub fn visitFloat(self: Self, comptime Error: type, input: anytype) Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Float, .ComptimeFloat => {},
                        else => @compileError("expected floating-point, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitFloat(self.context, Error, input);
            }

            pub fn visitInt(self: Self, comptime Error: type, input: anytype) Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Int, .ComptimeInt => {},
                        else => @compileError("expected integer, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitInt(self.context, Error, input);
            }

            pub fn visitMap(self: Self, mapAccess: anytype) blk: {
                concepts.@"getty.de.MapAccess"(@TypeOf(mapAccess));

                break :blk @TypeOf(mapAccess).Error!Value;
            } {
                return try visitMap(self.context, mapAccess);
            }

            pub fn visitNull(self: Self, comptime Error: type) Error!Value {
                return try visitNull(self.context, Error);
            }

            ///
            ///
            /// The visitor is responsible for visiting the entire sequence. Note
            /// that this implies that `sequenceAccess` must be able to identify
            /// the end of a sequence when it is encountered.
            pub fn visitSequence(self: Self, sequenceAccess: anytype) blk: {
                concepts.@"getty.de.SequenceAccess"(@TypeOf(sequenceAccess));

                break :blk @TypeOf(sequenceAccess).Error!Value;
            } {
                return try visitSequence(self.context, sequenceAccess);
            }

            pub fn visitSome(self: Self, deserializer: anytype) blk: {
                concepts.@"getty.Deserializer"(@TypeOf(deserializer));

                break :blk @TypeOf(deserializer).Error!Value;
            } {
                return try visitSome(self.context, deserializer);
            }

            ///
            ///
            /// The visitor is responsible for visiting the entire slice.
            pub fn visitString(self: Self, comptime Error: type, input: anytype) Error!Value {
                comptime {
                    if (!std.meta.trait.isZigString(@TypeOf(input))) {
                        @compileError("expected string, found `" ++ @typeName(@TypeOf(input)) ++ "`");
                    }
                }

                return try visitString(self.context, Error, input);
            }

            pub fn visitVoid(self: Self, comptime Error: type) Error!Value {
                return try visitVoid(self.context, Error);
            }
        };

        pub fn visitor(ctx: Context) @"getty.de.Visitor" {
            return .{ .context = ctx };
        }
    };
}
