const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const assert = std.debug.assert;

pub fn Visitor(
    comptime Context: type,
    comptime Value: type,
    comptime visitBool: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: bool) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitEnum: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitFloat: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitInt: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitMap: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitNull: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitSeq: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitSome: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            unreachable;
        }
    }.f),
    comptime visitString: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitUnion: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
    comptime visitVoid: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.Visitor" = struct {
            context: Context,

            const Self = @This();

            pub const Value = Value;

            pub fn visitBool(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
                return try visitBool(self.context, allocator, Deserializer, input);
            }

            pub fn visitEnum(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Enum, .EnumLiteral => {},
                        else => @compileError("expected enum or enum literal, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitEnum(self.context, allocator, Deserializer, input);
            }

            pub fn visitFloat(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Float, .ComptimeFloat => {},
                        else => @compileError("expected floating-point, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitFloat(self.context, allocator, Deserializer, input);
            }

            pub fn visitInt(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Int, .ComptimeInt => {},
                        else => @compileError("expected integer, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitInt(self.context, allocator, Deserializer, input);
            }

            pub fn visitMap(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) blk: {
                concepts.@"getty.de.Map"(@TypeOf(map));

                break :blk Deserializer.Error!Value;
            } {
                return try visitMap(self.context, allocator, Deserializer, map);
            }

            pub fn visitNull(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
                return try visitNull(self.context, allocator, Deserializer);
            }

            ///
            ///
            /// The visitor is responsible for visiting the entire sequence. Note
            /// that this implies that `seq` must be able to identify
            /// the end of a sequence when it is encountered.
            pub fn visitSeq(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) blk: {
                concepts.@"getty.de.Seq"(@TypeOf(seq));

                break :blk Deserializer.Error!Value;
            } {
                return try visitSeq(self.context, allocator, Deserializer, seq);
            }

            pub fn visitSome(self: Self, allocator: ?std.mem.Allocator, deserializer: anytype) blk: {
                concepts.@"getty.Deserializer"(@TypeOf(deserializer));

                break :blk @TypeOf(deserializer).Error!Value;
            } {
                return try visitSome(self.context, allocator, deserializer);
            }

            ///
            ///
            /// The visitor is responsible for visiting the entire slice.
            pub fn visitString(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                comptime {
                    if (!std.meta.trait.isZigString(@TypeOf(input))) {
                        @compileError("expected string, found `" ++ @typeName(@TypeOf(input)) ++ "`");
                    }
                }

                return try visitString(self.context, allocator, Deserializer, input);
            }

            pub fn visitUnion(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, access: anytype) blk: {
                concepts.@"getty.de.UnionAccess"(@TypeOf(access));

                break :blk Deserializer.Error!Value;
            } {
                return try visitUnion(self.context, allocator, Deserializer, access);
            }

            pub fn visitVoid(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
                return try visitVoid(self.context, allocator, Deserializer);
            }
        };

        pub fn visitor(ctx: Context) @"getty.de.Visitor" {
            return .{ .context = ctx };
        }
    };
}
