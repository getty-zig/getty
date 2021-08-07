const std = @import("std");
const de = @import("getty").de;

const meta = std.meta;
const trait = meta.trait;
const testing = std.testing;

fn Deserializer(comptime T: type) type {
    return struct {
        value: T,

        const Self = @This();

        const Error = error{
            DeserializationError,
        };

        pub fn init(value: T) Self {
            return .{ .value = value };
        }

        /// Implements `getty.de.Deserializer`.
        pub fn deserializer(self: *Self) D {
            return .{ .context = self };
        }

        const D = de.Deserializer(
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

        const _D = struct {
            fn deserializeAny(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return switch (@typeInfo(T)) {
                    .Bool => visitor.visitBool(true),
                    .Int => visitor.visitInt(self.value),
                    .Pointer => |info| {
                        return switch (info.size) {
                            .One => switch (@typeInfo(info.child)) {
                                .Array => blk: {
                                    var child_deserializer = Deserializer([]const meta.Elem(info.child)).init(self.value);
                                    const child_d = child_deserializer.deserializer();
                                    break :blk child_d.deserializeAny(visitor);
                                },
                                else => try deserializeAny(self, serializer, value.*),
                            },
                            .Slice => blk: {
                                if (comptime trait.isZigString(T)) {
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

            fn deserializeBool(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

            fn deserializeInt(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

            fn deserializeFloat(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

            fn deserializeOption(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                if (self.value == null) {
                    return visitor.visitNull() catch return Error.DeserializationError;
                } else {
                    return visitor.visitSome(self.value.?) catch return Error.DeserializationError;
                }
            }

            fn deserializeSequence(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

            fn deserializeString(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

            fn deserializeStruct(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
                return deserializeAny(self, visitor);
            }

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
    pub fn visitor(self: *Self) V {
        return .{ .context = self };
    }

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

    const _V = struct {
        fn visitBool(self: *Self, value: bool) Error!Ok {
            _ = self;
            _ = value;

            return .Bool;
        }

        fn visitInt(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .Int;
        }

        fn visitFloat(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .Float;
        }

        fn visitNull(self: *Self) Error!Ok {
            _ = self;

            return .Null;
        }

        fn visitSome(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .Some;
        }

        fn visitSequence(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .Sequence;
        }

        fn visitString(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .String;
        }

        fn visitStruct(self: *Self, value: anytype) Error!Ok {
            _ = self;
            _ = value;

            return .Struct;
        }

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
                    .Array => try t(@as([]const meta.Elem(info.child), input), output),
                    else => try t(input.*, output),
                }

                return;
            },
            .Slice => blk: {
                if (comptime trait.isZigString(@TypeOf(input))) {
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

    try testing.expect(o == output);
}

comptime {
    testing.refAllDecls(@This());
}
