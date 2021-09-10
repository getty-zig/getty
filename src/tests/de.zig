const std = @import("std");
const getty = @import("getty");

const testing = std.testing;

const Token = union(enum) {
    Bool: bool,
    Enum: enum { foo, bar },
    Float: f64,
    Int: i64,
    Null: ?bool,
    Some: ?bool,
    Sequence: [2]bool,
    Slice: []const u8,
    Struct: struct { x: i64, y: i64 },
    Void: void,
};

/// A data format that deserializes `Token` values.
const Deserializer = struct {
    value: Token,

    const Self = @This();

    pub fn init(token: Token) Self {
        return .{ .value = token };
    }

    /// Implements `getty.de.Deserializer`.
    pub usingnamespace getty.de.Deserializer(
        *Self,
        _D.Error,
        _D.deserializeBool,
        _D.deserializeEnum,
        _D.deserializeFloat,
        _D.deserializeInt,
        undefined,
        //_D.deserializeMap,
        _D.deserializeOptional,
        _D.deserializeSequence,
        _D.deserializeSlice,
        undefined,
        //_D.deserializeStruct,
        _D.deserializeVoid,
    );

    const _D = struct {
        const Error = error{Input};

        fn deserializeBool(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Bool => |value| try visitor.visitBool(Error, value),
                else => Error.Input,
            };
        }

        fn deserializeEnum(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Enum => |value| try visitor.visitEnum(Error, value),
                else => Error.Input,
            };
        }

        fn deserializeFloat(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Float => |value| try visitor.visitFloat(Error, value),
                .Int => |value| try visitor.visitInt(Error, value),
                else => Error.Input,
            };
        }

        fn deserializeInt(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Float => |value| try visitor.visitFloat(Error, value),
                .Int => |value| try visitor.visitInt(Error, value),
                else => Error.Input,
            };
        }

        fn deserializeOptional(self: *Self, allocator: ?*std.mem.Allocator, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Null => try visitor.visitNull(Error),
                .Some => blk: {
                    // we know Some is a ?bool, so simulate parsing the
                    // optional into its child type.
                    const value = self.value.Some.?;
                    self.value = .{ .Bool = value };

                    break :blk try visitor.visitSome(allocator, self.deserializer());
                },
                else => Error.Input,
            };
        }

        fn deserializeSlice(self: *Self, allocator: *std.mem.Allocator, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Slice => |value| try visitor.visitSlice(allocator, Error, value),
                else => Error.Input,
            };
        }

        fn deserializeSequence(self: *Self, allocator: ?*std.mem.Allocator, visitor: anytype) !@TypeOf(visitor).Value {
            if (self.value != .Sequence) {
                return Error.Input;
            }

            var sequenceValue = struct {
                allocator: ?*std.mem.Allocator,
                seq: [2]bool,
                i: usize = 0,

                const SV = @This();

                /// Implements `getty.de.SequenceAccess`.
                pub usingnamespace getty.de.SequenceAccess(
                    *SV,
                    Error,
                    _SA.nextElementSeed,
                );

                const _SA = struct {
                    /// Sequence accesses specify how to access *and* deserialize
                    /// elements of a sequence.
                    ///
                    /// In this case, since we know every sequence is a
                    /// [2]bool, we just do an index check and then deserialize
                    /// the current bool using a new deserializer. We could
                    /// have also simply called `deserializeBool` directly
                    /// instead of creating a new deserializer if the seed
                    /// doesn't need to be used.
                    ///
                    /// For a deserializer that works with JSON or some other
                    /// string data format, instead of incrementing an index
                    /// like we do here, wed'd simply parse up until the next
                    /// character before we return from the function. For
                    /// example:
                    ///
                    ///   1. If ']' is encountered, `null` is returned to
                    ///      indicate the end of the sequence.
                    ///
                    ///   2. If an element is encountered, then it is
                    ///      deserialized and the deserialized value is returned.
                    ///
                    ///   3. If ',' is encountered, the comma and any subsequent
                    ///      whitespace is eaten. If ']' is encountered, an
                    ///      error is returned for having a trailing comma. If,
                    ///      instead, an element is encountered, then go to 2).
                    fn nextElementSeed(sv: *SV, seed: anytype) !?@TypeOf(seed).Value {
                        if (sv.i == sv.seq.len) return null;
                        defer sv.i += 1;

                        var deserializer = Self.init(Token{ .Bool = sv.seq[sv.i] });
                        const d = deserializer.deserializer();
                        return try seed.deserialize(sv.allocator, d);
                    }
                };
            }{
                .allocator = allocator,
                .seq = self.value.Sequence,
            };

            return try visitor.visitSequence(sequenceValue.sequenceAccess());
        }

        //fn deserializeMap(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
        //_ = self;

        //var access = struct {
        //i: i64 = 0,

        //pub usingnamespace getty.de.MapAccess(
        //*@This(),
        //Error,
        //nextKeySeed,
        //undefined,
        //);

        //fn nextKeySeed(a: *@This(), seed: anytype) !?@TypeOf(seed).Value {
        //defer a.i += 1;

        //var deserializer = Self.init(Token{ .Int = a.i + 1 });
        //const d = deserializer.deserializer();
        //return try seed.deserialize(std.testing.allocator, d);
        //}

        //fn nextValueSeed(mv: *@This(), seed: anytype) !@TypeOf(seed).Value {
        //}
        //}{};
        //return try visitor.visitMap(access.mapAccess());
        //}

        //fn deserializeStruct(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
        //if (self.value != .Struct) {
        //return Error.Input;
        //}

        //return try deserializeMap(self, visitor);
        //}

        fn deserializeVoid(self: *Self, visitor: anytype) !@TypeOf(visitor).Value {
            if (self.value != .Void) {
                return Error.Input;
            }

            return try visitor.visitVoid(Error);
        }
    };
};

test "array" {
    const tests = .{
        .{
            .desc = "non-empty",
            .input = Token{ .Sequence = .{ true, true } },
            .Output = [2]bool,
            .output = [2]bool{ true, true },
        },
        .{
            .desc = "non-empty",
            .input = Token{ .Sequence = .{ false, false } },
            .Output = [2]bool,
            .output = [2]bool{ false, false },
        },
    };

    inline for (tests) |t| {
        var d = Deserializer.init(t.input);
        try testing.expectEqual(t.output, try getty.deserialize(null, @TypeOf(t.output), d.deserializer()));
    }
}

test "bool" {
    const tests = .{
        .{
            .desc = "true",
            .input = Token{ .Bool = true },
            .Output = bool,
            .output = true,
        },
        .{
            .desc = "false",
            .input = Token{ .Bool = false },
            .Output = bool,
            .output = false,
        },
    };

    inline for (tests) |t| {
        var d = Deserializer.init(t.input);
        try testing.expectEqual(t.output, try getty.deserialize(null, @TypeOf(t.output), d.deserializer()));
    }
}

test "float" {
    const tests = .{
        .{
            .desc = "conversion to equal bit size",
            .input = Token{ .Float = 3.14 },
            .output = @as(f64, 3.14),
        },
        .{
            .desc = "conversion to higher bit size",
            .input = Token{ .Float = 1.0 },
            .output = @as(f128, 1.0),
        },
        .{
            .desc = "conversion from integer",
            .input = Token{ .Int = 1 },
            .output = @intToFloat(f64, 1),
        },
    };

    inline for (tests) |t| {
        var d = Deserializer.init(t.input);
        try testing.expectEqual(t.output, try getty.deserialize(null, @TypeOf(t.output), d.deserializer()));
    }
}

test "int" {
    const tests = .{
        .{
            .desc = "conversion to equal bit size",
            .input = Token{ .Int = 1 },
            .output = @as(i64, 1),
        },
        .{
            .desc = "conversion to higher bit size",
            .input = Token{ .Int = 1 },
            .output = @as(i128, 1),
        },
        .{
            .desc = "conversion from float",
            .input = Token{ .Float = 1.0 },
            .output = @as(i64, 1),
        },
        .{
            .desc = "conversion to different sign",
            .input = Token{ .Int = std.math.maxInt(i64) },
            .Output = u64,
            .output = @as(u64, std.math.maxInt(i64)),
        },
    };

    inline for (tests) |t| {
        var d = Deserializer.init(t.input);
        try testing.expectEqual(t.output, try getty.deserialize(null, @TypeOf(t.output), d.deserializer()));
    }
}

test "slice" {
    const tests = .{
        .{
            .desc = "[]const u8",
            .input = Token{ .Slice = "Hello, World" },
            .output = @as([]const u8, "Hello, World"),
        },
    };

    inline for (tests) |t| {
        var d = Deserializer.init(t.input);
        const result = try getty.deserialize(std.testing.allocator, @TypeOf(t.output), d.deserializer());
        defer std.testing.allocator.free(result);

        try testing.expect(std.mem.eql(u8, t.output, result));
    }
}

//test "struct" {
//const tests = .{
//.{
//.desc = "basic",
//.input = Token{ .Struct = .{ .x = 1, .y = 2 } },
//.output = .{ .x = 1, .y = 2 },
//},
//};

//inline for (tests) |t| {
//var d = Deserializer.init(t.input);
//try testing.expectEqual(t.output, try getty.deserialize(std.testing.allocator, @TypeOf(t.output), d.deserializer()));
//}
//}

test "optional" {
    const tests = .{
        .{
            .desc = "null",
            .input = Token{ .Null = null },
            .output = @as(?bool, null),
        },
        .{
            .desc = "some",
            .input = Token{ .Some = true },
            .output = @as(?bool, true),
        },
    };

    inline for (tests) |t| {
        var d = Deserializer.init(t.input);
        try testing.expectEqual(t.output, try getty.deserialize(null, @TypeOf(t.output), d.deserializer()));
    }
}

test "void" {
    var d = Deserializer.init(Token{ .Void = {} });
    try testing.expectEqual({}, try getty.deserialize(null, void, d.deserializer()));
}

test {
    testing.refAllDecls(@This());
}
