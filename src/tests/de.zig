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
            _D.deserializeFloat,
            _D.deserializeInt,
            _D.deserializeMap,
            _D.deserializeOptional,
            _D.deserializeSequence,
            _D.deserializeString,
            _D.deserializeStruct,
            _D.deserializeVariant,
            _D.deserializeVoid,
        );

        const _D = struct {
            fn deserializeAny(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return switch (@typeInfo(T)) {
                    .Bool => visitor.visitBool(Error, self.value),
                    .Enum => visitor.visitVariant(Error, self.value),
                    .Int => visitor.visitInt(Error, self.value),
                    .Float => visitor.visitFloat(Error, self.value),
                    .Pointer => |info| {
                        return switch (info.size) {
                            .One => switch (@typeInfo(info.child)) {
                                .Array => blk: {
                                    var child_deserializer = Deserializer(t).init(self.value);
                                    const child_d = child_deserializer.deserializer();
                                    break :blk child_d.deserializeAny(visitor);
                                },
                                else => try deserializeAny(self, value.*),
                            },
                            .Slice => blk: {
                                if (comptime trait.isZigString(T)) {
                                    break :blk visitor.visitString(Error, self.value) catch Error.DeserializationError;
                                } else {
                                    @compileError("non-String slice: " ++ @typeName(T));
                                }
                            },
                            else => @compileError("unsupported serialize type: " ++ @typeName(T)),
                        };
                    },
                    .Null => visitor.visitNull(Error),
                    .Void => visitor.visitVoid(Error),
                    else => @compileError("Unsupported"),
                } catch Error.DeserializationError;
            }

            fn deserializeBool(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return deserializeAny(self, visitor);
            }

            fn deserializeFloat(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return deserializeAny(self, visitor);
            }

            fn deserializeInt(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return deserializeAny(self, visitor);
            }

            fn deserializeMap(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                _ = self;
                //return visitor.visitMap(self.value),
            }

            fn deserializeOptional(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                if (self.value) |_| {
                    return visitor.visitSome(self.deserializer()) catch Error.DeserializationError;
                } else {
                    return visitor.visitNull(Error) catch Error.DeserializationError;
                }
            }

            fn deserializeSequence(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return deserializeAny(self, visitor);
            }

            fn deserializeString(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return deserializeAny(self, visitor);
            }

            fn deserializeStruct(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return deserializeMap(self, visitor);
            }

            fn deserializeVariant(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return deserializeAny(self, visitor);
            }

            fn deserializeVoid(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Value {
                return deserializeAny(self, visitor);
            }
        };
    };
}

/// Provides a Visitor access to each element of a sequence in the input.
fn Sequence(comptime E: type) type {
    return struct {
        const Self = @This();

        const Error = E;

        /// Implements `getty.de.SequenceAccess`.
        pub fn sequenceAccess(self: *Self) SA {
            return .{ .context = self };
        }

        const SA = de.SequenceAccess(
            *Self,
            Error,
            _SA.nextElementSeed,
        );

        const _SA = struct {
            fn nextElementSeed(self: *Self, seed: anytype) Error!?@TypeOf(seed).Value {
                _ = self;
            }
        };
    };
}

/// A visitor that deserializes Zig data types supported by Getty into boolean
/// values.
const Visitor = struct {
    const Self = @This();

    const Value = bool;

    /// Implements `getty.de.Visitor`.
    pub fn visitor(self: *Self) V {
        return .{ .context = self };
    }

    const V = de.Visitor(
        *Self,
        Value,
        _V.visitBool,
        _V.visitFloat,
        _V.visitInt,
        _V.visitMap,
        _V.visitNull,
        _V.visitSequence,
        _V.visitSome,
        _V.visitString,
        _V.visitVariant,
        _V.visitVoid,
    );

    const _V = struct {
        fn visitBool(self: *Self, comptime Error: type, input: bool) Error!Value {
            _ = self;

            return input;
        }

        fn visitInt(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;

            return if (input > 0) true else false;
        }

        fn visitFloat(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            return if (input > 0.0) true else false;
        }

        fn visitMap(self: *Self, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            _ = self;

            return .Map;
        }

        fn visitNull(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            return false;
        }

        fn visitSequence(self: *Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
            _ = self;

            return .Sequence;
        }

        fn visitSome(self: *Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            _ = self;

            return true;
        }

        fn visitString(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            return if (input.len > 0) true else false;
        }

        fn visitVariant(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            return true;
        }

        fn visitVoid(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            return false;
        }
    };
};

fn SequenceAccess(comptime T: type) type {
    return struct {
        deserializer: Deserializer(T),

        const Self = @This();

        pub fn init(deserializer: Deserializer(T)) Self {
            return .{ .deserializer = deserializer };
        }

        /// Implements `getty.de.SequenceAccess`.
        pub fn seqAccess(self: *Self) SA {
            return .{ .context = self };
        }

        const SA = getty.de.SequenceAccess(
            *Self,
            Error,
            _SA.nextSeed,
        );

        const _SA = struct {
            fn next(self: *Self, seed: anytype) Error!?@TypeOf(seed).Value {
                _ = self;
                //if (_self.remaining > 0) {
                //_self.remaining -= 1;
                //return try seed.deserialize();
                //}
                //return null;
            }
        };
    };
}

//test "Sequence" {
//try t([_]u8{}, false);
//try t([_]u8{ 1, 2, 3 }, true);
//}

test "Boolean" {
    try t(false, false);
    try t(true, true);
}

test "Enum" {
    //try t(.Foo, true); // TODO: parameter of type '(enum literal)' must be declared comptime

    try t(enum { A }.A, true);
}

test "Float" {
    //try t(1.0, .Int); // TODO: Let comptime types be tested

    try t(@as(f32, 0.0), false);
    try t(@as(f32, 1.0), true);
}

test "Integer" {
    //try t(1, .Int); // TODO: Let comptime types be tested

    try t(@as(u8, 0), false);
    try t(@as(i8, 0), false);
    try t(@as(i8, -1), false);

    try t(@as(u8, 1), true);
    try t(@as(i8, 1), true);
}

test "String" {
    try t("", false);
    try t("A", true);

    try t(&[_]u8{}, false);
    try t(&[_]u8{'A'}, true);
}

//test "Struct" {
//try t(.{ .a = "foo", .b = "bar" }, true);
//}

test "Optional" {
    try t(@as(?bool, null), false);

    try t(@as(?bool, false), true);
    try t(@as(?bool, true), true);
}

test "Void" {
    try t({}, false);
}

fn t(input: anytype, expected: bool) !void {
    const T = @TypeOf(input);

    var visitor = Visitor{};
    const v = visitor.visitor();

    var deserializer = Deserializer(T).init(input);
    const d = deserializer.deserializer();

    const got = switch (@typeInfo(T)) {
        .Bool => try d.deserializeBool(v),
        .Enum => try d.deserializeVariant(v),
        .Float => try d.deserializeFloat(v),
        .Int => try d.deserializeInt(v),
        .Optional => try d.deserializeOptional(v),
        .Pointer => |info| switch (info.size) {
            .One => {
                switch (@typeInfo(info.child)) {
                    .Array => try t(@as([]const meta.Elem(info.child), input), expected),
                    else => try t(input.*, expected),
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
            else => @compileError("unsupported serialize type: " ++ @typeName(T)),
        },
        .Struct => try d.deserializeStruct(v),
        .Void => try d.deserializeVoid(v),
        else => @compileError("unsupported serialize type: " ++ @typeName(T)),
    };

    try testing.expect(got == expected);
}

test "Void (II)" {
    const value: void = {};

    var deserializer = Deserializer(void).init(value);
    const d = deserializer.deserializer();

    const result = try de.deserialize(void, &d);

    try std.testing.expect(result == {});
}

test "Bool (II)" {
    const T = bool;

    {
        const value = false;

        var deserializer = Deserializer(T).init(value);
        const d = deserializer.deserializer();

        const result = try de.deserialize(T, &d);

        try std.testing.expect(result == false);
    }

    {
        const value = true;

        var deserializer = Deserializer(T).init(value);
        const d = deserializer.deserializer();

        const result = try de.deserialize(T, &d);

        try std.testing.expect(result == true);
    }
}

test "Integer (II)" {
    {
        const T = i8;

        // signed to signed
        {
            const value: T = 1;

            var deserializer = Deserializer(T).init(value);
            const d = deserializer.deserializer();

            const result = try de.deserialize(T, &d);
            const Result = @TypeOf(result);

            try std.testing.expectEqual(result, 1);
            try std.testing.expectEqual(Result, T);
        }

        // signed to unsigned (pass)
        {
            const value: T = 1;

            var deserializer = Deserializer(T).init(value);
            const d = deserializer.deserializer();

            const result = try de.deserialize(u8, &d);
            const Result = @TypeOf(result);

            try std.testing.expectEqual(result, 1);
            try std.testing.expectEqual(Result, u8);
        }

        // signed to unsigned (fail)
        {
            const value: T = std.math.minInt(T);

            var deserializer = Deserializer(T).init(value);
            const d = deserializer.deserializer();

            const err = de.deserialize(u8, &d) catch |err| err;

            try std.testing.expectError(@TypeOf(d).Error.DeserializationError, err);
        }
    }

    {
        const T = u8;

        // unsigned to unsigned
        {
            const value: T = 1;

            var deserializer = Deserializer(T).init(value);
            const d = deserializer.deserializer();

            const result = try de.deserialize(T, &d);
            const Result = @TypeOf(result);

            try std.testing.expectEqual(result, 1);
            try std.testing.expectEqual(Result, T);
        }

        // unsigned to signed (pass)
        {
            const value: T = 1;

            var deserializer = Deserializer(T).init(value);
            const d = deserializer.deserializer();

            const result = try de.deserialize(i8, &d);
            const Result = @TypeOf(result);

            try std.testing.expectEqual(result, 1);
            try std.testing.expectEqual(Result, i8);
        }

        // unsigned to signed (fail)
        {
            const value: T = std.math.maxInt(T);

            var deserializer = Deserializer(T).init(value);
            const d = deserializer.deserializer();

            const err = de.deserialize(i8, &d) catch |err| err;

            try std.testing.expectError(@TypeOf(d).Error.DeserializationError, err);
        }
    }
}

test "Float (II)" {
    const T = f32;

    // f32 to f32
    {
        const value: T = std.math.f32_max;

        var deserializer = Deserializer(T).init(value);
        const d = deserializer.deserializer();

        const result = try de.deserialize(T, &d);
        const Result = @TypeOf(result);

        try std.testing.expectEqual(result, std.math.f32_max);
        try std.testing.expectEqual(Result, T);
    }

    // f32 to f64
    {
        const value: T = std.math.f32_max;

        var deserializer = Deserializer(T).init(value);
        const d = deserializer.deserializer();

        const result = try de.deserialize(f64, &d);
        const Result = @TypeOf(result);

        try std.testing.expectEqual(result, std.math.f32_max);
        try std.testing.expectEqual(Result, f64);
    }

    // f32 to f16 (pass)
    {
        const value: T = std.math.f16_max;

        var deserializer = Deserializer(T).init(value);
        const d = deserializer.deserializer();

        const result = try de.deserialize(f16, &d);
        const Result = @TypeOf(result);

        try std.testing.expectEqual(result, std.math.f16_max);
        try std.testing.expectEqual(Result, f16);
    }

    // f32 to f16 (fail)
    {
        const value: T = std.math.f32_max;

        var deserializer = Deserializer(T).init(value);
        const d = deserializer.deserializer();

        const result = try de.deserialize(f16, &d);

        try std.testing.expectEqual(result, @floatCast(f16, std.math.f32_max));
        try std.testing.expectEqual(@TypeOf(result), f16);
    }
}

comptime {
    testing.refAllDecls(@This());
}
