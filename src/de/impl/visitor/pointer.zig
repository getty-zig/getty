const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Pointer: type) type {
    if (@typeInfo(Pointer) != .Pointer or @typeInfo(Pointer).Pointer.size != .One) {
        @compileError("expected one pointer, found `" ++ @typeName(Pointer) ++ "`");
    }

    return struct {
        allocator: std.mem.Allocator,

        const Self = @This();
        const impl = @"impl Visitor"(Pointer);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.Value,
            impl.visitor.visitBool,
            impl.visitor.visitEnum,
            impl.visitor.visitFloat,
            impl.visitor.visitInt,
            impl.visitor.visitMap,
            impl.visitor.visitNull,
            impl.visitor.visitSequence,
            impl.visitor.visitString,
            impl.visitor.visitSome,
            impl.visitor.visitVoid,
        );
    };
}

fn @"impl Visitor"(comptime Pointer: type) type {
    const Self = Visitor(Pointer);

    return struct {
        pub const visitor = struct {
            pub const Value = Pointer;

            pub fn visitBool(self: Self, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
                var child_visitor = blk: {
                    inline for (Deserializer.with) |w| {
                        if (comptime w.is(Child)) {
                            break :blk w.visitor(self.allocator, Child);
                        }
                    }

                    @compileError("type ` " ++ @typeName(Child) ++ "` is not supported");
                };

                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);
                value.* = try child_visitor.visitor().visitBool(Deserializer, input);

                return value;
            }

            pub fn visitEnum(self: Self, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                var child_visitor = blk: {
                    inline for (Deserializer.with) |w| {
                        if (comptime w.is(Child)) {
                            break :blk w.visitor(self.allocator, Child);
                        }
                    }

                    @compileError("type ` " ++ @typeName(Child) ++ "` is not supported");
                };

                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);
                value.* = try child_visitor.visitor().visitEnum(Deserializer, input);

                return value;
            }

            pub fn visitFloat(self: Self, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                var child_visitor = blk: {
                    inline for (Deserializer.with) |w| {
                        if (comptime w.is(Child)) {
                            break :blk w.visitor(self.allocator, Child);
                        }
                    }

                    @compileError("type ` " ++ @typeName(Child) ++ "` is not supported");
                };

                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);
                value.* = try child_visitor.visitor().visitFloat(Deserializer, input);

                return value;
            }

            pub fn visitInt(self: Self, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                var child_visitor = blk: {
                    inline for (Deserializer.with) |w| {
                        if (comptime w.is(Child)) {
                            break :blk w.visitor(self.allocator, Child);
                        }
                    }

                    @compileError("type ` " ++ @typeName(Child) ++ "` is not supported");
                };

                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);
                value.* = try child_visitor.visitor().visitInt(Deserializer, input);

                return value;
            }

            pub fn visitMap(self: Self, comptime Deserializer: type, mapAccess: anytype) Deserializer.Error!Value {
                var child_visitor = blk: {
                    inline for (Deserializer.with) |w| {
                        if (comptime w.is(Child)) {
                            break :blk w.visitor(self.allocator, Child);
                        }
                    }

                    @compileError("type ` " ++ @typeName(Child) ++ "` is not supported");
                };

                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);
                value.* = try child_visitor.visitor().visitMap(Deserializer, mapAccess);

                return value;
            }

            pub fn visitNull(self: Self, comptime Deserializer: type) Deserializer.Error!Value {
                var child_visitor = blk: {
                    inline for (Deserializer.with) |w| {
                        if (comptime w.is(Child)) {
                            break :blk w.visitor(self.allocator, Child);
                        }
                    }

                    @compileError("type ` " ++ @typeName(Child) ++ "` is not supported");
                };

                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);
                value.* = try child_visitor.visitor().visitNull(Deserializer);

                return value;
            }

            pub fn visitSequence(self: Self, comptime Deserializer: type, seqAccess: anytype) Deserializer.Error!Value {
                var child_visitor = blk: {
                    inline for (Deserializer.with) |w| {
                        if (comptime w.is(Child)) {
                            break :blk w.visitor(self.allocator, Child);
                        }
                    }

                    @compileError("type ` " ++ @typeName(Child) ++ "` is not supported");
                };

                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);
                value.* = try child_visitor.visitor().visitSequence(Deserializer, seqAccess);

                return value;
            }

            pub fn visitString(self: Self, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
                var child_visitor = blk: {
                    inline for (Deserializer.with) |w| {
                        if (comptime w.is(Child)) {
                            break :blk w.visitor(self.allocator, Child);
                        }
                    }

                    @compileError("type ` " ++ @typeName(Child) ++ "` is not supported");
                };

                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);
                value.* = try child_visitor.visitor().visitString(Deserializer, input);

                return value;
            }

            pub fn visitSome(self: Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
                var child_visitor = blk: {
                    const Deserializer = @TypeOf(deserializer);

                    inline for (Deserializer.with) |w| {
                        if (comptime w.is(Child)) {
                            break :blk w.visitor(self.allocator, Child);
                        }
                    }

                    @compileError("type ` " ++ @typeName(Child) ++ "` is not supported");
                };

                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);
                value.* = try child_visitor.visitor().visitSome(deserializer);

                return value;
            }

            pub fn visitVoid(self: Self, comptime Deserializer: type) Deserializer.Error!Value {
                var child_visitor = blk: {
                    inline for (Deserializer.with) |w| {
                        if (comptime w.is(Child)) {
                            break :blk w.visitor(self.allocator, Child);
                        }
                    }

                    @compileError("type ` " ++ @typeName(Child) ++ "` is not supported");
                };

                const value = try self.allocator.create(Child);
                errdefer getty.de.free(self.allocator, value);
                value.* = try child_visitor.visitor().visitVoid(Deserializer);

                return value;
            }

            const Child = std.meta.Child(Pointer);
        };
    };
}
