const std = @import("std");
const assert = std.debug.assert;

const StringLifetime = @import("../lifetime.zig").StringLifetime;

/// A `Visitor` deserializes values from Getty's data model into Zig.
pub fn Visitor(
    /// An implementing type.
    comptime Impl: type,
    /// The type of the value produced by the visitor.
    comptime T: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        visitBool: VisitBoolFn(Impl, T) = null,
        visitFloat: VisitAnyFn(Impl, T) = null,
        visitInt: VisitAnyFn(Impl, T) = null,
        visitMap: VisitAnyFn(Impl, T) = null,
        visitNull: VisitNothingFn(Impl, T) = null,
        visitSeq: VisitAnyFn(Impl, T) = null,
        visitSome: VisitSomeFn(Impl, T) = null,
        visitString: VisitStringFn(Impl, T) = null,
        visitUnion: VisitUnionFn(Impl, T) = null,
        visitVoid: VisitNothingFn(Impl, T) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.Visitor" = struct {
            impl: Impl,

            const Self = @This();

            pub const Value = T;

            pub fn visitBool(self: Self, ally: std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Err!T {
                if (methods.visitBool) |func| {
                    return try func(self.impl, ally, Deserializer, input);
                }

                return error.Unsupported;
            }

            pub fn visitFloat(self: Self, ally: std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Err!T {
                if (methods.visitFloat) |func| {
                    comptime {
                        switch (@typeInfo(@TypeOf(input))) {
                            .Float, .ComptimeFloat => {},
                            else => @compileError("expected float, found: " ++ @typeName(@TypeOf(input))),
                        }
                    }

                    return try func(self.impl, ally, Deserializer, input);
                }

                return error.Unsupported;
            }

            pub fn visitInt(self: Self, ally: std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Err!T {
                if (methods.visitInt) |func| {
                    comptime {
                        switch (@typeInfo(@TypeOf(input))) {
                            .Int, .ComptimeInt => {},
                            else => @compileError("expected integer, found: " ++ @typeName(@TypeOf(input))),
                        }
                    }

                    return try func(self.impl, ally, Deserializer, input);
                }

                return error.Unsupported;
            }

            pub fn visitMap(self: Self, ally: std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Err!T {
                if (methods.visitMap) |func| {
                    return try func(self.impl, ally, Deserializer, map);
                }

                return error.Unsupported;
            }

            pub fn visitNull(self: Self, ally: std.mem.Allocator, comptime Deserializer: type) Deserializer.Err!T {
                if (methods.visitNull) |func| {
                    return try func(self.impl, ally, Deserializer);
                }

                return error.Unsupported;
            }

            ///
            ///
            /// The visitor is responsible for visiting the entire sequence. Note
            /// that this implies that `seq` must be able to identify
            /// the end of a sequence when it is encountered.
            pub fn visitSeq(self: Self, ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!T {
                if (methods.visitSeq) |func| {
                    return try func(self.impl, ally, Deserializer, seq);
                }

                return error.Unsupported;
            }

            pub fn visitSome(self: Self, ally: std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Err!T {
                if (methods.visitSome) |func| {
                    return try func(self.impl, ally, deserializer);
                }

                return error.Unsupported;
            }

            ///
            ///
            /// The visitor is responsible for visiting the entire slice.
            pub fn visitString(
                self: Self,
                ally: std.mem.Allocator,
                comptime Deserializer: type,
                input: anytype,
                lifetime: StringLifetime,
            ) Deserializer.Err!VisitStringReturn(T) {
                if (methods.visitString) |func| {
                    comptime {
                        if (!std.meta.trait.isZigString(@TypeOf(input))) {
                            @compileError("expected string, found: " ++ @typeName(@TypeOf(input)));
                        }
                    }

                    return try func(self.impl, ally, Deserializer, input, lifetime);
                }

                return error.Unsupported;
            }

            pub fn visitUnion(self: Self, ally: std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Err!T {
                if (methods.visitUnion) |func| {
                    return try func(self.impl, ally, Deserializer, ua, va);
                }

                return error.Unsupported;
            }

            pub fn visitVoid(self: Self, ally: std.mem.Allocator, comptime Deserializer: type) Deserializer.Err!T {
                if (methods.visitVoid) |func| {
                    return try func(self.impl, ally, Deserializer);
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

/// The return value of a `getty.de.Visitor`'s `visitString` method.
pub fn VisitStringReturn(comptime T: type) type {
    return struct {
        value: T,
        used: bool,
    };
}

fn VisitAnyFn(comptime Impl: type, comptime T: type) type {
    const Lambda = struct {
        fn func(impl: Impl, ally: std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Err!T {
            _ = impl;
            _ = ally;
            _ = input;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn VisitBoolFn(comptime Impl: type, comptime T: type) type {
    const Lambda = struct {
        fn func(impl: Impl, ally: std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Err!T {
            _ = impl;
            _ = ally;
            _ = input;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn VisitNothingFn(comptime Impl: type, comptime T: type) type {
    const Lambda = struct {
        fn func(impl: Impl, ally: std.mem.Allocator, comptime Deserializer: type) Deserializer.Err!T {
            _ = impl;
            _ = ally;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}
fn VisitSomeFn(comptime Impl: type, comptime T: type) type {
    const Lambda = struct {
        fn func(impl: Impl, ally: std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Err!T {
            _ = impl;
            _ = ally;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn VisitStringFn(comptime Impl: type, comptime T: type) type {
    const Lambda = struct {
        fn func(
            impl: Impl,
            ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
            lifeitime: StringLifetime,
        ) Deserializer.Err!VisitStringReturn(T) {
            _ = lifeitime;
            _ = impl;
            _ = ally;
            _ = input;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn VisitUnionFn(comptime Impl: type, comptime T: type) type {
    const Lambda = struct {
        fn func(impl: Impl, ally: std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Err!T {
            _ = impl;
            _ = ally;
            _ = ua;
            _ = va;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}
