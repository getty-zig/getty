const std = @import("std");

const de = @import("../../de.zig");

const assert = std.debug.assert;

pub fn Visitor(
    comptime Context: type,
    comptime V: type,
    comptime visitBoolFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: bool) Deserializer.Error!V {
            unreachable;
        }
    }.f),
    comptime visitEnumFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
            unreachable;
        }
    }.f),
    comptime visitFloatFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
            unreachable;
        }
    }.f),
    comptime visitIntFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
            unreachable;
        }
    }.f),
    comptime visitMapFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
            unreachable;
        }
    }.f),
    comptime visitNullFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!V {
            unreachable;
        }
    }.f),
    comptime visitSeqFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
            unreachable;
        }
    }.f),
    comptime visitSomeFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!V {
            unreachable;
        }
    }.f),
    comptime visitStringFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
            unreachable;
        }
    }.f),
    comptime visitUnionFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype, _: anytype) Deserializer.Error!V {
            unreachable;
        }
    }.f),
    comptime visitVoidFn: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!V {
            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.Visitor" = struct {
            context: Context,

            const Self = @This();

            pub const Value = V;

            pub fn visitBool(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
                return try visitBoolFn(self.context, allocator, Deserializer, input);
            }

            pub fn visitEnum(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Enum, .EnumLiteral => {},
                        else => @compileError("expected enum or enum literal, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitEnumFn(self.context, allocator, Deserializer, input);
            }

            pub fn visitFloat(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Float, .ComptimeFloat => {},
                        else => @compileError("expected floating-point, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitFloatFn(self.context, allocator, Deserializer, input);
            }

            pub fn visitInt(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                comptime {
                    switch (@typeInfo(@TypeOf(input))) {
                        .Int, .ComptimeInt => {},
                        else => @compileError("expected integer, found `" ++ @typeName(@TypeOf(input)) ++ "`"),
                    }
                }

                return try visitIntFn(self.context, allocator, Deserializer, input);
            }

            pub fn visitMap(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) blk: {
                de.concepts.@"getty.de.MapAccess"(@TypeOf(map));

                break :blk Deserializer.Error!Value;
            } {
                return try visitMapFn(self.context, allocator, Deserializer, map);
            }

            pub fn visitNull(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
                return try visitNullFn(self.context, allocator, Deserializer);
            }

            ///
            ///
            /// The visitor is responsible for visiting the entire sequence. Note
            /// that this implies that `seq` must be able to identify
            /// the end of a sequence when it is encountered.
            pub fn visitSeq(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) blk: {
                de.concepts.@"getty.de.SeqAccess"(@TypeOf(seq));

                break :blk Deserializer.Error!Value;
            } {
                return try visitSeqFn(self.context, allocator, Deserializer, seq);
            }

            pub fn visitSome(self: Self, allocator: ?std.mem.Allocator, deserializer: anytype) blk: {
                de.concepts.@"getty.Deserializer"(@TypeOf(deserializer));

                break :blk @TypeOf(deserializer).Error!Value;
            } {
                return try visitSomeFn(self.context, allocator, deserializer);
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

                return try visitStringFn(self.context, allocator, Deserializer, input);
            }

            pub fn visitUnion(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) blk: {
                de.concepts.@"getty.de.UnionAccess"(@TypeOf(ua));
                de.concepts.@"getty.de.VariantAccess"(@TypeOf(va));

                break :blk Deserializer.Error!Value;
            } {
                return try visitUnionFn(self.context, allocator, Deserializer, ua, va);
            }

            pub fn visitVoid(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
                return try visitVoidFn(self.context, allocator, Deserializer);
            }
        };

        pub fn visitor(ctx: Context) @"getty.de.Visitor" {
            return .{ .context = ctx };
        }
    };
}
