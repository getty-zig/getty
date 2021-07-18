const std = @import("std");
const de = @import("getty").de;

fn Deserializer(comptime T: type) type {
    return struct {
        value: T,

        const Self = @This();

        pub fn init(value: T) Self {
            return .{ .value = value };
        }

        /// Implements `getty.de.Deserializer`.
        pub const D = de.Deserializer(
            *Self,
            Error,
            _D.deserializeAny,
            _D.deserializeBool,
            _D.deserializeInt,
            _D.deserializeFloat,
            _D.deserializeOption,
            _D.deserializeSequence,
            _D.deserializeString,
            _D.deserializeStruct,
            _D.deserializeVariant,
        );

        pub fn deserializer(self: *Self) D {
            return .{ .context = self };
        }

        pub const Error = error{
            DeserializationError,
        };

        const _D = struct {
            /// Implements `anyFn` for `getty.de.Deserializer`.
            fn deserializeAny(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return switch (@typeInfo(T)) {
                    .Bool => visitor.visitBool(true),
                    .Int => visitor.visitInt(self.value),
                    .Pointer => |info| {
                        return switch (info.size) {
                            .One => switch (@typeInfo(info.child)) {
                                .Array => blk: {
                                    var child_deserializer = Deserializer([]const std.meta.Elem(info.child)).init(self.value);
                                    const child_d = child_deserializer.deserializer();
                                    break :blk child_d.deserializeAny(visitor);
                                },
                                else => try deserializeAny(self, serializer, value.*),
                            },
                            .Slice => blk: {
                                if (comptime std.meta.trait.isZigString(T)) {
                                    break :blk visitor.visitString(self.value) catch Error.DeserializationError;
                                } else {
                                    @compileError("non-String slice: " ++ @typeName(T));
                                }
                            },
                            else => @compileError("unsupported serialize type: " ++ @typeName(T)),
                        };
                    },
                    .Null => visitor.visitNull(),
                    .Struct => visitor.visitStruct(self.value),
                    .Enum => visitor.visitVariant(self.value),
                    else => @compileError("Unimplemented"),
                } catch Error.DeserializationError;
            }

            /// Implements `boolFn` for `getty.de.Deserializer`.
            fn deserializeBool(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

            /// Implements `intFn` for `getty.de.Deserializer`.
            fn deserializeInt(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

            /// Implements `floatFn` for `getty.de.Deserializer`.
            fn deserializeFloat(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

            /// Implements `optionFn` for `getty.de.Deserializer`.
            fn deserializeOption(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                if (self.value == null) {
                    return visitor.visitNull() catch return Error.DeserializationError;
                } else {
                    return visitor.visitSome(self.value.?) catch return Error.DeserializationError;
                }
            }

            /// Implements `sequenceFn` for `getty.de.Deserializer`.
            fn deserializeSequence(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

            /// Implements `stringFn` for `getty.de.Deserializer`.
            fn deserializeString(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

            /// Implements `structFn` for `getty.de.Deserializer`.
            fn deserializeStruct(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

            /// Implements `variantFn` for `getty.de.Deserializer`.
            fn deserializeVariant(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }
        };
    };
}

const Token = enum {
    Bool,
    Int,
    Float,
    Null,
    Some,
    Sequence,
    String,
    Struct,
    Variant,
};

const Visitor = struct {
    const Self = @This();

    const Ok = Token;
    const Error = error{VisitorError};

    /// Implements `getty.de.Visitor`.
    const V = de.Visitor(
        *Self,
        Ok,
        Error,
        _V.visitBool,
        _V.visitInt,
        _V.visitFloat,
        _V.visitNull,
        _V.visitSome,
        _V.visitSequence,
        _V.visitString,
        _V.visitStruct,
        _V.visitVariant,
    );

    pub fn visitor(self: *Self) V {
        return .{ .context = self };
    }

    const _V = struct {
        /// Implements `boolFn` for `getty.de.Visitor`.
        fn visitBool(self: *Self, value: bool) Error!Ok {
            _ = self;
            _ = value;

            return .Bool;
        }

        /// Implements `intFn` for `getty.de.Visitor`.
        fn visitInt(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .Int;
        }

        /// Implements `floatFn` for `getty.de.Visitor`.
        fn visitFloat(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .Float;
        }

        /// Implements `nullFn` for `getty.de.Visitor`.
        fn visitNull(self: *Self) Error!Ok {
            _ = self;

            return .Null;
        }

        /// Implements `someFn` for `getty.de.Visitor`.
        fn visitSome(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .Some;
        }

        /// Implements `sequenceFn` for `getty.de.Visitor`.
        fn visitSequence(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .Sequence;
        }

        /// Implements `stringFn` for `getty.de.Visitor`.
        fn visitString(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .String;
        }

        /// Implements `structFn` for `getty.de.Visitor`.
        fn visitStruct(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .Struct;
        }

        /// Implements `variantFn` for `getty.de.Visitor`.
        fn visitVariant(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .Variant;
        }
    };
};

test "Boolean" {
    try t(true, .Bool);
}

test "Integer" {
    //try t(1, .Int); // TODO: Let comptime types be tested
    try t(@as(u8, 1), .Int);
    try t(@as(i8, -1), .Int);
}

test "String" {
    try t("a", .String);
    try t(&[_]u8{'a'}, .String);
}

test "Struct" {
    try t(.{ .a = "foo", .b = "bar" }, .Struct);
}

test "Optional" {
    try t(@as(?i8, 1), .Some);
    try t(@as(?i8, null), .Null);
}

test "Enum" {
    //try t(.Foo, .Variant); // TODO: parameter of type '(enum literal)' must be declared comptime
    try t(enum { Foo }.Foo, .Variant);
}

fn t(input: anytype, output: Token) !void {
    var visitor = Visitor{};
    const v = visitor.visitor();

    var deserializer = Deserializer(@TypeOf(input)).init(input);
    const d = deserializer.deserializer();

    const o = switch (@typeInfo(@TypeOf(input))) {
        .Bool => try d.deserializeBool(v),
        .Enum => try d.deserializeVariant(v),
        .Int => try d.deserializeInt(v),
        .Optional => try d.deserializeOption(v),
        .Pointer => |info| switch (info.size) {
            .One => {
                switch (@typeInfo(info.child)) {
                    .Array => try t(@as([]const std.meta.Elem(info.child), input), output),
                    else => try t(input.*, output),
                }

                return;
            },
            .Slice => blk: {
                if (comptime std.meta.trait.isZigString(@TypeOf(input))) {
                    break :blk try d.deserializeString(v);
                } else {
                    @compileError("Non-string slice");
                }
            },
            else => @compileError("unsupported serialize type: " ++ @typeName(@TypeOf(input))),
        },
        .Struct => try d.deserializeStruct(v),
        else => unreachable,
    };

    try std.testing.expect(o == output);
}

comptime {
    std.testing.refAllDecls(@This());
}
