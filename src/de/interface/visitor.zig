const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const assert = std.debug.assert;

pub fn Visitor(
    comptime Context: type,
    comptime Value: type,
    comptime visitBool: @TypeOf(struct {
        fn f(_: Context, comptime Deserializer: type, _: bool) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitEnum: @TypeOf(struct {
        fn f(_: Context, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitFloat: @TypeOf(struct {
        fn f(_: Context, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitInt: @TypeOf(struct {
        fn f(_: Context, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitMap: @TypeOf(struct {
        fn f(_: Context, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            unreachable;
        }
    }.f),
    comptime visitNull: @TypeOf(struct {
        fn f(_: Context, comptime Deserializer: type) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitSequence: @TypeOf(struct {
        fn f(_: Context, seqAccess: anytype) @TypeOf(seqAccess).Error!Value {
            unreachable;
        }
    }.f),
    comptime visitString: @TypeOf(struct {
        fn f(_: Context, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitSome: @TypeOf(struct {
        fn f(_: Context, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            unreachable;
        }
    }.f),
    comptime visitVoid: @TypeOf(struct {
        fn f(_: Context, comptime Deserializer: type) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.Visitor" = struct {
            context: Context,

            const Self = @This();

            pub const Value = Value;

            pub fn visitBool(self: Self, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
                return try visitBool(self.context, Deserializer, input);
            }

            pub fn visitEnum(self: Self, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Enum, .EnumLiteral => {},
                        else => @compileError("expected enum or enum literal, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitEnum(self.context, Deserializer, input);
            }

            pub fn visitFloat(self: Self, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Float, .ComptimeFloat => {},
                        else => @compileError("expected floating-point, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitFloat(self.context, Deserializer, input);
            }

            pub fn visitInt(self: Self, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Int, .ComptimeInt => {},
                        else => @compileError("expected integer, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitInt(self.context, Deserializer, input);
            }

            pub fn visitMap(self: Self, mapAccess: anytype) blk: {
                concepts.@"getty.de.MapAccess"(@TypeOf(mapAccess));

                break :blk @TypeOf(mapAccess).Error!Value;
            } {
                return try visitMap(self.context, mapAccess);
            }

            pub fn visitNull(self: Self, comptime Deserializer: type) Deserializer.Error!Value {
                return try visitNull(self.context, Deserializer);
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
            pub fn visitString(self: Self, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                comptime {
                    if (!std.meta.trait.isZigString(@TypeOf(input))) {
                        @compileError("expected string, found `" ++ @typeName(@TypeOf(input)) ++ "`");
                    }
                }

                return try visitString(self.context, Deserializer, input);
            }

            pub fn visitVoid(self: Self, comptime Deserializer: type) Deserializer.Error!Value {
                return try visitVoid(self.context, Deserializer);
            }
        };

        pub fn visitor(ctx: Context) @"getty.de.Visitor" {
            return .{ .context = ctx };
        }
    };
}
