const std = @import("std");
const assert = std.debug.assert;

/// A `Visitor` deserializes values from Getty's data model into Zig.
pub fn Visitor(
    /// An implementing type.
    comptime Impl: type,
    /// The type of the value produced by the visitor.
    comptime V: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        visitBool: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, comptime Deserializer: type, _: bool) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitFloat: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitInt: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitMap: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitNull: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitSeq: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitSome: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!V {
                unreachable;
            }
        }.f) = null,
        visitString: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitUnion: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype, _: anytype) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
        visitVoid: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!V {
                unreachable;
            }
        }.f) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.Visitor" = struct {
            impl: Impl,

            const Self = @This();

            pub const Value = V;

            pub fn visitBool(self: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
                if (methods.visitBool) |f| {
                    return try f(self.impl, ally, Deserializer, input);
                }

                return error.Unsupported;
            }

            pub fn visitFloat(self: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                if (methods.visitFloat) |f| {
                    comptime {
                        switch (@typeInfo(@TypeOf(input))) {
                            .Float, .ComptimeFloat => {},
                            else => @compileError("expected float, found: " ++ @typeName(@TypeOf(input))),
                        }
                    }

                    return try f(self.impl, ally, Deserializer, input);
                }

                return error.Unsupported;
            }

            pub fn visitInt(self: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                if (methods.visitInt) |f| {
                    comptime {
                        switch (@typeInfo(@TypeOf(input))) {
                            .Int, .ComptimeInt => {},
                            else => @compileError("expected integer, found: " ++ @typeName(@TypeOf(input))),
                        }
                    }

                    return try f(self.impl, ally, Deserializer, input);
                }

                return error.Unsupported;
            }

            pub fn visitMap(self: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
                if (methods.visitMap) |f| {
                    return try f(self.impl, ally, Deserializer, map);
                }

                return error.Unsupported;
            }

            pub fn visitNull(self: Self, ally: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
                if (methods.visitNull) |f| {
                    return try f(self.impl, ally, Deserializer);
                }

                return error.Unsupported;
            }

            ///
            ///
            /// The visitor is responsible for visiting the entire sequence. Note
            /// that this implies that `seq` must be able to identify
            /// the end of a sequence when it is encountered.
            pub fn visitSeq(self: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
                if (methods.visitSeq) |f| {
                    return try f(self.impl, ally, Deserializer, seq);
                }

                return error.Unsupported;
            }

            pub fn visitSome(self: Self, ally: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
                if (methods.visitSome) |f| {
                    return try f(self.impl, ally, deserializer);
                }

                return error.Unsupported;
            }

            ///
            ///
            /// The visitor is responsible for visiting the entire slice.
            pub fn visitString(self: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                if (methods.visitString) |f| {
                    comptime {
                        if (!std.meta.trait.isZigString(@TypeOf(input))) {
                            @compileError("expected string, found: " ++ @typeName(@TypeOf(input)));
                        }
                    }

                    return try f(self.impl, ally, Deserializer, input);
                }

                return error.Unsupported;
            }

            pub fn visitUnion(self: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Error!Value {
                if (methods.visitUnion) |f| {
                    return try f(self.impl, ally, Deserializer, ua, va);
                }

                return error.Unsupported;
            }

            pub fn visitVoid(self: Self, ally: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
                if (methods.visitVoid) |f| {
                    return try f(self.impl, ally, Deserializer);
                }

                return error.Unsupported;
            }
        };

        /// Returns an interface value.
        pub fn visitor(impl: Impl) @"getty.de.Visitor" {
            return .{ .impl = impl };
        }
    };
}
