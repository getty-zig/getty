const std = @import("std");

const de = @import("../../de.zig");

const assert = std.debug.assert;

/// Deserialization visitor interface.
pub fn Visitor(
    /// The namespace that owns the method implementations provided in `methods`.
    comptime Context: type,
    /// The type of the value produced by the visitor.
    comptime V: type,
    /// A namespace for the methods that implementations of the interface can implement.
    comptime methods: struct {
        visitBool: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: bool) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitEnum: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitFloat: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitInt: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitMap: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitNull: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitSeq: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitSome: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!V {
                unreachable;
            }
        }.f) = null,
        visitString: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitUnion: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitVoid: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.Visitor" = struct {
            context: Context,

            const Self = @This();

            pub const Value = V;

            pub fn visitBool(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
                if (methods.visitBool) |f| {
                    return try f(self.context, allocator, Deserializer, input);
                }

                @compileError("visitBool is not implemented by type: " ++ @typeName(Context));
            }

            pub fn visitEnum(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                if (methods.visitEnum) |f| {
                    comptime {
                        switch (@typeInfo(@TypeOf(input))) {
                            .Enum, .EnumLiteral => {},
                            else => @compileError("expected enum or enum literal, found: " ++ @typeName(@TypeOf(input))),
                        }
                    }

                    return try f(self.context, allocator, Deserializer, input);
                }

                @compileError("visitEnum is not implemented by type: " ++ @typeName(Context));
            }

            pub fn visitFloat(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                if (methods.visitFloat) |f| {
                    comptime {
                        switch (@typeInfo(@TypeOf(input))) {
                            .Float, .ComptimeFloat => {},
                            else => @compileError("expected float, found: " ++ @typeName(@TypeOf(input))),
                        }
                    }

                    return try f(self.context, allocator, Deserializer, input);
                }

                @compileError("visitFloat is not implemented by type: " ++ @typeName(Context));
            }

            pub fn visitInt(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                if (methods.visitInt) |f| {
                    comptime {
                        switch (@typeInfo(@TypeOf(input))) {
                            .Int, .ComptimeInt => {},
                            else => @compileError("expected integer, found: " ++ @typeName(@TypeOf(input))),
                        }
                    }

                    return try f(self.context, allocator, Deserializer, input);
                }

                @compileError("visitInt is not implemented by type: " ++ @typeName(Context));
            }

            pub fn visitMap(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) blk: {
                de.concepts.@"getty.de.MapAccess"(@TypeOf(map));

                break :blk Deserializer.Error!Value;
            } {
                if (methods.visitMap) |f| {
                    return try f(self.context, allocator, Deserializer, map);
                }

                @compileError("visitMap is not implemented by type: " ++ @typeName(Context));
            }

            pub fn visitNull(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
                if (methods.visitNull) |f| {
                    return try f(self.context, allocator, Deserializer);
                }

                @compileError("visitNull is not implemented by type: " ++ @typeName(Context));
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
                if (methods.visitSeq) |f| {
                    return try f(self.context, allocator, Deserializer, seq);
                }

                @compileError("visitSeq is not implemented by type: " ++ @typeName(Context));
            }

            pub fn visitSome(self: Self, allocator: ?std.mem.Allocator, deserializer: anytype) blk: {
                de.concepts.@"getty.Deserializer"(@TypeOf(deserializer));

                break :blk @TypeOf(deserializer).Error!Value;
            } {
                if (methods.visitSome) |f| {
                    return try f(self.context, allocator, deserializer);
                }

                @compileError("visitSome is not implemented by type: " ++ @typeName(Context));
            }

            ///
            ///
            /// The visitor is responsible for visiting the entire slice.
            pub fn visitString(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                if (methods.visitString) |f| {
                    comptime {
                        if (!std.meta.trait.isZigString(@TypeOf(input))) {
                            @compileError("expected string, found: " ++ @typeName(@TypeOf(input)));
                        }
                    }

                    return try f(self.context, allocator, Deserializer, input);
                }

                @compileError("visitString is not implemented by type: " ++ @typeName(Context));
            }

            pub fn visitUnion(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) blk: {
                de.concepts.@"getty.de.UnionAccess"(@TypeOf(ua));
                de.concepts.@"getty.de.VariantAccess"(@TypeOf(va));

                break :blk Deserializer.Error!Value;
            } {
                if (methods.visitUnion) |f| {
                    return try f(self.context, allocator, Deserializer, ua, va);
                }

                @compileError("visitUnion is not implemented by type: " ++ @typeName(Context));
            }

            pub fn visitVoid(self: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
                if (methods.visitVoid) |f| {
                    return try f(self.context, allocator, Deserializer);
                }

                @compileError("visitVoid is not implemented by type: " ++ @typeName(Context));
            }
        };

        /// Returns an interface value.
        pub fn visitor(ctx: Context) @"getty.de.Visitor" {
            return .{ .context = ctx };
        }
    };
}
