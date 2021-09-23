const std = @import("std");
const getty = @import("getty");

const testing = std.testing;

const TestBool = bool;
const TestFloat = f64;
const TestInt = i64;
const TestEnum = enum { foo, bar };
const TestOptional = ?bool;
const TestPoint = struct { x: i64, y: i64 };
const TestSequence = [2]bool;
const TestSlice = []const u8;
const TestVoid = void;

const Token = union(enum) {
    Bool: TestBool,
    Enum: TestEnum,
    Float: TestFloat,
    Int: TestInt,
    Null: TestOptional,
    Some: TestOptional,
    Sequence: TestSequence,
    Slice: TestSlice,
    Struct: TestPoint,
    Void: TestVoid,
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
        _D.deserializeMap,
        _D.deserializeOptional,
        _D.deserializeSequence,
        _D.deserializeSlice,
        _D.deserializeStruct,
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
                .Int => |value| try visitor.visitInt(Error, value),
                .Slice => |value| try visitor.visitSlice(std.testing.allocator, Error, value),
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

            return try visitor.visitSequence(allocator, sequenceValue.sequenceAccess());
        }

        fn deserializeSlice(self: *Self, allocator: *std.mem.Allocator, visitor: anytype) !@TypeOf(visitor).Value {
            return switch (self.value) {
                .Slice => |value| try visitor.visitSlice(allocator, Error, value),
                else => Error.Input,
            };
        }

        fn deserializeMap(self: *Self, allocator: ?*std.mem.Allocator, visitor: anytype) !@TypeOf(visitor).Value {
            var access = struct {
                arena: ?std.heap.ArenaAllocator,
                structure: TestPoint,
                i: i64 = 0,

                pub usingnamespace getty.de.MapAccess(
                    *@This(),
                    Error,
                    nextKeySeed,
                    nextValueSeed,
                );

                // FIXME: Make sure we test when the input map is longer than
                // the map we're deserializing into. Specifically, the else
                // right now signifies the end of the map, but that may not be
                // the case (e.g., missing closing brace, another entry).
                fn nextKeySeed(a: *@This(), seed: anytype) !?@TypeOf(seed).Value {
                    defer a.i += 1;

                    return switch (a.i) {
                        0 => "x",
                        1 => "y",
                        else => null,
                    };
                }

                fn nextValueSeed(a: *@This(), seed: anytype) !@TypeOf(seed).Value {
                    // `a.i` is incremented by `nextKeySeed`, so this works for
                    // the value .{ .x = 1, .y = 2 }.
                    var deserializer = Self.init(Token{ .Int = a.i });
                    const d = deserializer.deserializer();

                    return try seed.deserialize(if (a.arena) |*arena| &arena.allocator else null, d);
                }
            }{
                .arena = if (allocator) |alloc| std.heap.ArenaAllocator.init(alloc) else null,
                .structure = self.value.Struct,
            };
            errdefer if (access.arena) |arena| arena.deinit();

            return try visitor.visitMap(allocator, access.mapAccess());
        }

        fn deserializeStruct(self: *Self, allocator: ?*std.mem.Allocator, visitor: anytype) !@TypeOf(visitor).Value {
            if (self.value != .Struct) {
                return Error.Input;
            }

            return try deserializeMap(self, allocator, visitor);
        }

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

test "enum" {
    const tests = .{
        .{
            .desc = "integer",
            .input = Token{ .Int = 0 },
            .Output = TestEnum,
            .output = TestEnum.foo,
        },
        .{
            .desc = "string",
            .input = Token{ .Slice = "bar" },
            .Output = TestEnum,
            .output = TestEnum.bar,
        },
        .{
            .desc = "enum",
            .input = Token{ .Enum = TestEnum.foo },
            .Output = TestEnum,
            .output = TestEnum.foo,
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

test "struct" {
    const tests = .{
        .{
            .desc = "basic",
            .input = Token{ .Struct = .{ .x = 1, .y = 2 } },
            .output = TestPoint{ .x = 1, .y = 2 },
        },
    };

    inline for (tests) |t| {
        var d = Deserializer.init(t.input);
        const result = try getty.deserialize(null, @TypeOf(t.output), d.deserializer());

        try testing.expectEqual(t.output.x, result.x);
        try testing.expectEqual(t.output.y, result.y);
    }
}

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
