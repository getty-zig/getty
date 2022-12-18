//! Serialization framework.

const std = @import("std");

/// Serializer interface.
pub const Serializer = @import("ser/interfaces/serializer.zig").Serializer;

pub const default_st = .{
    ////////////////////////////////////////////////////////////////////////////
    // Standard Library
    ////////////////////////////////////////////////////////////////////////////

    ser.blocks.ArrayList,
    ser.blocks.BoundedArray,
    ser.blocks.BufMap,
    ser.blocks.HashMap,
    ser.blocks.LinkedList,
    ser.blocks.TailQueue,

    ////////////////////////////////////////////////////////////////////////////
    // Primitives
    ////////////////////////////////////////////////////////////////////////////

    ser.blocks.Array,
    ser.blocks.Bool,
    ser.blocks.Enum,
    ser.blocks.Error,
    ser.blocks.Float,
    ser.blocks.Int,
    ser.blocks.Null,
    ser.blocks.Optional,
    ser.blocks.Pointer,
    ser.blocks.Slice,
    ser.blocks.String,
    ser.blocks.Struct,
    ser.blocks.Tuple,
    ser.blocks.Union,
    ser.blocks.Vector,
    ser.blocks.Void,
};

pub const concepts = struct {
    pub usingnamespace @import("ser/concepts/serializer.zig");
    pub usingnamespace @import("ser/concepts/map.zig");
    pub usingnamespace @import("ser/concepts/seq.zig");
    pub usingnamespace @import("ser/concepts/structure.zig");
    pub usingnamespace @import("ser/concepts/block.zig");
};

pub const traits = struct {
    pub usingnamespace @import("ser/traits/block.zig");
    pub usingnamespace @import("ser/traits/attributes.zig");
};

/// A namespace for serialization-specific types and functions.
pub const ser = struct {
    /// Serialization interface for Getty Maps.
    pub const Map = @import("ser/interfaces/map.zig").Map;

    /// Serialization interface for Getty Sequences.
    pub const Seq = @import("ser/interfaces/seq.zig").Seq;

    /// Serialization interface for Getty Structures.
    pub const Structure = @import("ser/interfaces/structure.zig").Structure;

    /// Serialization blocks provided by Getty.
    pub const blocks = struct {
        ////////////////////////////////////////////////////////////////////////
        // Standard Library
        ////////////////////////////////////////////////////////////////////////

        /// Serialization block for `std.ArrayList` values.
        pub const ArrayList = @import("ser/blocks/array_list.zig");

        /// Serialization block for `std.BoundedArray` values.
        pub const BoundedArray = @import("ser/blocks/bounded_array.zig");

        /// Serialization block for `std.BufMap` values.
        pub const BufMap = @import("ser/blocks/buf_map.zig");

        /// Serialization block for `std.HashMap` values.
        pub const HashMap = @import("ser/blocks/hash_map.zig");

        /// Serialization block for `std.SinglyLinkedList` values.
        pub const LinkedList = @import("ser/blocks/linked_list.zig");

        /// Serialization block for `std.TailQueue`.
        pub const TailQueue = @import("ser/blocks/tail_queue.zig");

        ////////////////////////////////////////////////////////////////////////
        // Primitives
        ////////////////////////////////////////////////////////////////////////

        /// Serialization block for array values.
        pub const Array = @import("ser/blocks/array.zig");

        /// Serialization block for `bool` values.
        pub const Bool = @import("ser/blocks/bool.zig");

        /// Serialization block for `enum` values.
        pub const Enum = @import("ser/blocks/enum.zig");

        /// Serialization block for `error` values.
        pub const Error = @import("ser/blocks/error.zig");

        /// Serialization block for floating-point values.
        pub const Float = @import("ser/blocks/float.zig");

        /// Serialization block for integer values.
        pub const Int = @import("ser/blocks/int.zig");

        /// Serialization block for `null` values.
        pub const Null = @import("ser/blocks/null.zig");

        /// Serialization block for optional values.
        pub const Optional = @import("ser/blocks/optional.zig");

        /// Serialization block for pointer values.
        pub const Pointer = @import("ser/blocks/pointer.zig");

        /// Serialization block for slice values.
        pub const Slice = @import("ser/blocks/slice.zig");

        /// Serialization block for string values.
        pub const String = @import("ser/blocks/string.zig");

        /// Serialization block for `struct` values.
        pub const Struct = @import("ser/blocks/struct.zig");

        /// Serialization block for tuple values.
        pub const Tuple = @import("ser/blocks/tuple.zig");

        /// Serialization block for `union` values.
        pub const Union = @import("ser/blocks/union.zig");

        /// Serialization block for vector values.
        pub const Vector = @import("ser/blocks/vector.zig");

        /// Serialization block for `void` values.
        pub const Void = @import("ser/blocks/void.zig");
    };

    /// Returns the attributes for a type. If none exists, `null` is returned.
    pub fn getAttributes(
        /// The type for which attributes should be returned.
        comptime T: type,
        /// A `getty.Serializer` interface type.
        comptime S: type,
    ) blk: {
        // Process user SBs.
        for (S.user_st) |sb| {
            if (sb.is(T) and traits.has_attributes(T, sb)) {
                break :blk ?@TypeOf(sb.attributes);
            }
        }

        // Process type SBs.
        if (traits.has_sb(T)) {
            const sb = T.@"getty.sb";

            if (traits.has_attributes(T, sb)) {
                break :blk ?@TypeOf(sb.attributes);
            }
        }

        break :blk ?void;
    } {
        comptime {
            // Process user SBs.
            for (S.user_st) |sb| {
                if (sb.is(T) and traits.has_attributes(T, sb)) {
                    return @as(?@TypeOf(sb.attributes), sb.attributes);
                }
            }

            // Process type SBs.
            if (traits.has_sb(T)) {
                const sb = T.@"getty.sb";

                if (traits.has_attributes(T, sb)) {
                    return @as(?@TypeOf(sb.attributes), sb.attributes);
                }
            }

            return null;
        }
    }
};

/// Serializes a value.
pub fn serialize(
    /// A value to serialize.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) blk: {
    const S = @TypeOf(serializer);

    concepts.@"getty.Serializer"(S);

    break :blk S.Error!S.Ok;
} {
    const T = @TypeOf(value);

    const block = comptime blk: {
        // Process user SBs.
        for (@TypeOf(serializer).user_st) |sb| {
            if (sb.is(T)) {
                break :blk sb;
            }
        }

        // Process type SBs.
        if (traits.has_sb(T)) {
            break :blk T.@"getty.sb";
        }

        // Process serializer SBs.
        for (@TypeOf(serializer).serializer_st) |sb| {
            if (sb.is(T)) {
                break :blk sb;
            }
        }

        // Process default SBs.
        inline for (default_st) |sb| {
            if (sb.is(T)) {
                break :blk sb;
            }
        }

        @compileError("type is not supported: " ++ @typeName(T));
    };

    // Process attributes, if any exist.
    if (comptime traits.has_attributes(T, block)) {
        switch (@typeInfo(T)) {
            .Struct => return try ser.blocks.Struct.serialize(value, serializer),
            .Enum => return try ser.blocks.Enum.serialize(value, serializer),
            .Union => return try ser.blocks.Union.serialize(value, serializer),
            else => @compileError("unexpected type cannot be serialized using attributes"),
        }
    }

    return try block.serialize(value, serializer);
}

const Token = @import("tests/common.zig").Token;

const testing = std.testing;

const test_allocator = testing.allocator;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectEqualSlices = testing.expectEqualSlices;

const TestSerializer = struct {
    tokens: []const Token,

    const Self = @This();

    pub fn init(tokens: []const Token) Self {
        return .{ .tokens = tokens };
    }

    pub fn remaining(self: Self) usize {
        return self.tokens.len;
    }

    pub fn nextTokenOpt(self: *Self) ?Token {
        switch (self.remaining()) {
            0 => return null,
            else => |len| {
                const first = self.tokens[0];
                self.tokens = if (len == 1) &[_]Token{} else self.tokens[1..];
                return first;
            },
        }
    }

    pub usingnamespace Serializer(
        *Self,
        Ok,
        Error,
        null,
        null,
        Map,
        Seq,
        Structure,
        .{
            .serializeBool = serializeBool,
            .serializeEnum = serializeEnum,
            .serializeFloat = serializeFloat,
            .serializeInt = serializeInt,
            .serializeMap = serializeMap,
            .serializeNull = serializeNull,
            .serializeSeq = serializeSeq,
            .serializeSome = serializeSome,
            .serializeString = serializeString,
            .serializeStruct = serializeStruct,
            .serializeVoid = serializeVoid,
        },
    );

    const Ok = void;
    const Error = std.mem.Allocator.Error || error{TestExpectedEqual};

    fn serializeBool(self: *Self, v: bool) Error!Ok {
        try assertNextToken(self, Token{ .Bool = v });
    }

    fn serializeEnum(self: *Self, v: anytype) Error!Ok {
        try assertNextToken(self, Token{ .Enum = {} });
        try assertNextToken(self, Token{ .String = @tagName(v) });
    }

    fn serializeFloat(self: *Self, v: anytype) Error!Ok {
        var expected = switch (@typeInfo(@TypeOf(v))) {
            .ComptimeFloat => Token{ .ComptimeFloat = {} },
            .Float => |info| switch (info.bits) {
                16 => Token{ .F16 = v },
                32 => Token{ .F32 = v },
                64 => Token{ .F64 = v },
                128 => Token{ .F128 = v },
                else => @panic("unexpected float size"),
            },
            else => @panic("unexpected type"),
        };

        try assertNextToken(self, expected);
    }

    fn serializeInt(self: *Self, v: anytype) Error!Ok {
        var expected = switch (@typeInfo(@TypeOf(v))) {
            .ComptimeInt => Token{ .ComptimeInt = {} },
            .Int => |info| switch (info.signedness) {
                .signed => switch (info.bits) {
                    8 => Token{ .I8 = v },
                    16 => Token{ .I16 = v },
                    32 => Token{ .I32 = v },
                    64 => Token{ .I64 = v },
                    128 => Token{ .I128 = v },
                    else => @panic("unexpected integer size"),
                },
                .unsigned => switch (info.bits) {
                    8 => Token{ .U8 = v },
                    16 => Token{ .U16 = v },
                    32 => Token{ .U32 = v },
                    64 => Token{ .U64 = v },
                    128 => Token{ .U128 = v },
                    else => @panic("unexpected integer size"),
                },
            },
            else => @panic("unexpected type"),
        };

        try assertNextToken(self, expected);
    }

    fn serializeMap(self: *Self, length: ?usize) Error!Map {
        try assertNextToken(self, Token{ .Map = .{ .len = length } });

        return Map{ .ser = self };
    }

    fn serializeNull(self: *Self) Error!Ok {
        try assertNextToken(self, Token{ .Null = {} });
    }

    fn serializeSeq(self: *Self, length: ?usize) Error!Seq {
        try assertNextToken(self, Token{ .Seq = .{ .len = length } });
        return Seq{ .ser = self };
    }

    fn serializeSome(self: *Self, v: anytype) Error!Ok {
        try assertNextToken(self, Token{ .Some = {} });
        try serialize(v, self.serializer());
    }

    fn serializeString(self: *Self, v: anytype) Error!Ok {
        try assertNextToken(self, Token{ .String = v });
    }

    fn serializeStruct(self: *Self, comptime name: []const u8, length: usize) Error!Structure {
        try assertNextToken(self, Token{ .Struct = .{ .name = name, .len = length } });
        return Structure{ .ser = self };
    }

    fn serializeVoid(self: *Self) Error!Ok {
        try assertNextToken(self, Token{ .Void = {} });
    }

    const Map = struct {
        ser: *TestSerializer,

        pub usingnamespace ser.Map(
            *Map,
            Ok,
            Error,
            .{
                .serializeKey = serializeKey,
                .serializeValue = serializeValue,
                .end = end,
            },
        );

        fn serializeKey(self: *Map, key: anytype) Error!void {
            try serialize(key, self.ser.serializer());
        }

        fn serializeValue(self: *Map, value: anytype) Error!void {
            try serialize(value, self.ser.serializer());
        }

        fn end(self: *Map) Error!Ok {
            try assertNextToken(self.ser, Token{ .MapEnd = {} });
        }
    };

    const Seq = struct {
        ser: *TestSerializer,

        pub usingnamespace ser.Seq(
            *Seq,
            Ok,
            Error,
            .{
                .serializeElement = serializeElement,
                .end = end,
            },
        );

        fn serializeElement(self: *Seq, value: anytype) Error!void {
            try serialize(value, self.ser.serializer());
        }

        fn end(self: *Seq) Error!Ok {
            try assertNextToken(self.ser, Token{ .SeqEnd = {} });
        }
    };

    const Structure = struct {
        ser: *TestSerializer,

        pub usingnamespace ser.Structure(
            *Structure,
            Ok,
            Error,
            .{
                .serializeField = serializeField,
                .end = end,
            },
        );

        fn serializeField(self: *Structure, comptime key: []const u8, value: anytype) Error!void {
            try assertNextToken(self.ser, Token{ .String = key });
            try serialize(value, self.ser.serializer());
        }

        fn end(self: *Structure) Error!Ok {
            try assertNextToken(self.ser, Token{ .StructEnd = {} });
        }
    };

    fn assertNextToken(self: *Self, expected: Token) !void {
        if (self.nextTokenOpt()) |token| {
            const token_tag = std.meta.activeTag(token);
            const expected_tag = std.meta.activeTag(expected);

            if (token_tag == expected_tag) {
                switch (token) {
                    .Bool => try expectEqual(@field(token, "Bool"), @field(expected, "Bool")),
                    .ComptimeFloat => try expectEqual(@field(token, "ComptimeFloat"), @field(expected, "ComptimeFloat")),
                    .ComptimeInt => try expectEqual(@field(token, "ComptimeInt"), @field(expected, "ComptimeInt")),
                    .Enum => try expectEqual(@field(token, "Enum"), @field(expected, "Enum")),
                    .F16 => try expectEqual(@field(token, "F16"), @field(expected, "F16")),
                    .F32 => try expectEqual(@field(token, "F32"), @field(expected, "F32")),
                    .F64 => try expectEqual(@field(token, "F64"), @field(expected, "F64")),
                    .F128 => try expectEqual(@field(token, "F128"), @field(expected, "F128")),
                    .I8 => try expectEqual(@field(token, "I8"), @field(expected, "I8")),
                    .I16 => try expectEqual(@field(token, "I16"), @field(expected, "I16")),
                    .I32 => try expectEqual(@field(token, "I32"), @field(expected, "I32")),
                    .I64 => try expectEqual(@field(token, "I64"), @field(expected, "I64")),
                    .I128 => try expectEqual(@field(token, "I128"), @field(expected, "I128")),
                    .Map => try expectEqual(@field(token, "Map"), @field(expected, "Map")),
                    .MapEnd => try expectEqual(@field(token, "MapEnd"), @field(expected, "MapEnd")),
                    .Null => try expectEqual(@field(token, "Null"), @field(expected, "Null")),
                    .Seq => try expectEqual(@field(token, "Seq"), @field(expected, "Seq")),
                    .SeqEnd => try expectEqual(@field(token, "SeqEnd"), @field(expected, "SeqEnd")),
                    .Some => try expectEqual(@field(token, "Some"), @field(expected, "Some")),
                    .String => try expectEqualSlices(u8, @field(token, "String"), @field(expected, "String")),
                    .Struct => {
                        const tok = @field(token, "Struct");
                        const e = @field(expected, "Struct");

                        try expectEqualSlices(u8, tok.name, e.name);
                        try expectEqual(tok.len, e.len);
                    },
                    .StructEnd => try expectEqual(@field(token, "StructEnd"), @field(expected, "StructEnd")),
                    .U8 => try expectEqual(@field(token, "U8"), @field(expected, "U8")),
                    .U16 => try expectEqual(@field(token, "U16"), @field(expected, "U16")),
                    .U32 => try expectEqual(@field(token, "U32"), @field(expected, "U32")),
                    .U64 => try expectEqual(@field(token, "U64"), @field(expected, "U64")),
                    .U128 => try expectEqual(@field(token, "U128"), @field(expected, "U128")),
                    .Union => @panic("TODO: unions"),
                    .Void => try expectEqual(@field(token, "Void"), @field(expected, "Void")),
                }
            } else {
                @panic("expected Token::{} but serialized as {}");
            }
        } else {
            @panic("expected end of tokens, but {} was serialized");
        }
    }
};

test "serialize - array" {
    try t([_]i32{}, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });
    try t([_]i32{ 1, 2, 3 }, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = {} },
    });
}

test "serialize - array list" {
    // managed
    {
        var list = std.ArrayList(std.ArrayList(u8)).init(test_allocator);
        defer list.deinit();

        var a = std.ArrayList(u8).init(test_allocator);
        defer a.deinit();

        var b = std.ArrayList(u8).init(test_allocator);
        defer b.deinit();

        var c = std.ArrayList(u8).init(test_allocator);
        defer c.deinit();

        try t(list, &[_]Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        });

        try b.append(1);
        try c.append(2);
        try c.append(3);
        try list.appendSlice(&[_]std.ArrayList(u8){ a, b, c });

        try t(list, &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 1 } },
            .{ .U8 = 1 },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 2 } },
            .{ .U8 = 2 },
            .{ .U8 = 3 },
            .{ .SeqEnd = {} },
            .{ .SeqEnd = {} },
        });
    }

    // unmanaged
    {
        var list = std.ArrayListUnmanaged(std.ArrayListUnmanaged(u8)){};
        defer list.deinit(test_allocator);

        var a = std.ArrayListUnmanaged(u8){};
        defer a.deinit(test_allocator);

        var b = std.ArrayListUnmanaged(u8){};
        defer b.deinit(test_allocator);

        var c = std.ArrayListUnmanaged(u8){};
        defer c.deinit(test_allocator);

        try t(list, &[_]Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        });

        try b.append(test_allocator, 1);
        try c.append(test_allocator, 2);
        try c.append(test_allocator, 3);
        try list.appendSlice(test_allocator, &[_]std.ArrayListUnmanaged(u8){ a, b, c });

        try t(list, &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 1 } },
            .{ .U8 = 1 },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 2 } },
            .{ .U8 = 2 },
            .{ .U8 = 3 },
            .{ .SeqEnd = {} },
            .{ .SeqEnd = {} },
        });
    }
}

test "serialize - bool" {
    try t(true, &[_]Token{.{ .Bool = true }});
    try t(false, &[_]Token{.{ .Bool = false }});
}

test "serialize - bounded array" {
    var empty = try std.BoundedArray(u8, 10).fromSlice(&[_]u8{});

    try t(empty, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    const array = [_]u8{1} ** 5;
    var non_empty = try std.BoundedArray(u8, 5).fromSlice(&array);

    try t(non_empty, &[_]Token{
        .{ .Seq = .{ .len = 5 } },
        .{ .U8 = 1 },
        .{ .U8 = 1 },
        .{ .U8 = 1 },
        .{ .U8 = 1 },
        .{ .U8 = 1 },
        .{ .SeqEnd = {} },
    });
}

test "serialize - buf map" {
    var map = std.BufMap.init(test_allocator);
    defer map.deinit();

    try t(map, &[_]Token{
        .{ .Map = .{ .len = 0 } },
        .{ .MapEnd = {} },
    });

    try map.put("1", "foobar");

    try t(map, &[_]Token{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "1" },
        .{ .String = "foobar" },
        .{ .MapEnd = {} },
    });
}

test "serialize - enum" {
    // literal
    try t(.foo, &[_]Token{ .{ .Enum = {} }, .{ .String = "foo" } });
    try t(.bar, &[_]Token{ .{ .Enum = {} }, .{ .String = "bar" } });

    // non-literal
    const T = enum { foo, bar };
    try t(T.foo, &[_]Token{ .{ .Enum = {} }, .{ .String = "foo" } });
    try t(T.bar, &[_]Token{ .{ .Enum = {} }, .{ .String = "bar" } });
}

test "serialize - error" {
    try t(error.Foobar, &[_]Token{.{ .String = "Foobar" }});
}

test "serialize - float" {
    // comptime_float
    try t(0.0, &[_]Token{.{ .ComptimeFloat = {} }});

    // float
    try t(@as(f16, 0), &[_]Token{.{ .F16 = 0 }});
    try t(@as(f32, 0), &[_]Token{.{ .F32 = 0 }});
    try t(@as(f64, 0), &[_]Token{.{ .F64 = 0 }});
    try t(@as(f128, 0), &[_]Token{.{ .F128 = 0 }});
}

test "serialize - hash map" {
    // managed
    {
        var map = std.AutoHashMap(i32, i32).init(test_allocator);
        defer map.deinit();

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put(1, 2);

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .MapEnd = {} },
        });
    }

    // unmanaged
    {
        var map = std.AutoHashMapUnmanaged(i32, i32){};
        defer map.deinit(test_allocator);

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put(test_allocator, 1, 2);

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .MapEnd = {} },
        });
    }

    // string
    {
        var map = std.StringHashMap(i32).init(test_allocator);
        defer map.deinit();

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put("1", 2);

        try t(map, &[_]Token{
            .{ .Map = .{ .len = 1 } },
            .{ .String = "1" },
            .{ .I32 = 2 },
            .{ .MapEnd = {} },
        });
    }
}

test "serialize - integer" {
    // comptime_int
    try t(0, &[_]Token{.{ .ComptimeInt = {} }});

    // signed
    try t(@as(i8, 0), &[_]Token{.{ .I8 = 0 }});
    try t(@as(i16, 0), &[_]Token{.{ .I16 = 0 }});
    try t(@as(i32, 0), &[_]Token{.{ .I32 = 0 }});
    try t(@as(i64, 0), &[_]Token{.{ .I64 = 0 }});
    try t(@as(i128, 0), &[_]Token{.{ .I128 = 0 }});

    // unsigned
    try t(@as(u8, 0), &[_]Token{.{ .U8 = 0 }});
    try t(@as(u16, 0), &[_]Token{.{ .U16 = 0 }});
    try t(@as(u32, 0), &[_]Token{.{ .U32 = 0 }});
    try t(@as(u64, 0), &[_]Token{.{ .U64 = 0 }});
    try t(@as(u128, 0), &[_]Token{.{ .U128 = 0 }});
}

test "serialize - linked list" {
    var list = std.SinglyLinkedList(i32){};

    try t(list, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    var one = @TypeOf(list).Node{ .data = 1 };
    var two = @TypeOf(list).Node{ .data = 2 };
    var three = @TypeOf(list).Node{ .data = 3 };

    list.prepend(&one);
    one.insertAfter(&two);
    two.insertAfter(&three);

    try t(list, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = {} },
    });
}

test "serialize - null" {
    try t(null, &[_]Token{.{ .Null = {} }});
}

test "serialize - optional" {
    try t(@as(?i32, null), &[_]Token{.{ .Null = {} }});
    try t(@as(?i32, 0), &[_]Token{ .{ .Some = {} }, .{ .I32 = 0 } });
}

test "serialize - pointer" {

    // one level of indirection
    {
        var ptr = try test_allocator.create(i32);
        defer test_allocator.destroy(ptr);
        ptr.* = @as(i32, 1);

        try t(ptr, &[_]Token{.{ .I32 = 1 }});
    }

    // two levels of indirection
    {
        var tmp = try test_allocator.create(i32);
        defer test_allocator.destroy(tmp);
        tmp.* = 2;

        var ptr = try test_allocator.create(*i32);
        defer test_allocator.destroy(ptr);
        ptr.* = tmp;

        try t(ptr, &[_]Token{.{ .I32 = 2 }});
    }

    // pointer to slice
    {
        var ptr = try test_allocator.create([]const u8);
        defer test_allocator.destroy(ptr);
        ptr.* = "3";

        try t(ptr, &[_]Token{.{ .String = "3" }});
    }
}

test "serialize - slice" {
    try t(&[_]i32{}, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });
    try t(&[_]i32{ 1, 2, 3 }, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = {} },
    });
}

test "serialize - string" {
    try t("abc", &[_]Token{.{ .String = "abc" }});
    try t(&[_]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
    try t(&[_:0]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
}

test "serialize - struct" {
    const Struct = struct { a: i32, b: i32, c: i32 };

    try t(Struct{ .a = 1, .b = 2, .c = 3 }, &[_]Token{
        .{ .Struct = .{ .name = @typeName(Struct), .len = 3 } },
        .{ .String = "a" },
        .{ .I32 = 1 },
        .{ .String = "b" },
        .{ .I32 = 2 },
        .{ .String = "c" },
        .{ .I32 = 3 },
        .{ .StructEnd = {} },
    });
}

test "serialize - tail queue" {
    var list = std.TailQueue(i32){};

    try t(list, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    var one = @TypeOf(list).Node{ .data = 1 };
    var two = @TypeOf(list).Node{ .data = 2 };
    var three = @TypeOf(list).Node{ .data = 3 };

    list.append(&one);
    list.append(&two);
    list.append(&three);

    try t(list, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = {} },
    });
}

test "serialize - tuple" {
    try t(.{}, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    try t(std.meta.Tuple(&[_]type{ i32, bool }){ 1, true }, &[_]Token{
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .Bool = true },
        .{ .SeqEnd = {} },
    });

    try t(.{ @as(i32, 1), true }, &[_]Token{
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .Bool = true },
        .{ .SeqEnd = {} },
    });
}

test "serialize - union" {
    const Union = union(enum) { Int: i32, Bool: bool };

    try t(Union{ .Int = 0 }, &[_]Token{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Int" },
        .{ .I32 = 0 },
        .{ .MapEnd = {} },
    });
    try t(Union{ .Bool = true }, &[_]Token{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Bool" },
        .{ .Bool = true },
        .{ .MapEnd = {} },
    });
}

test "serialize - vector" {
    try t(@splat(2, @as(i32, 1)), &[_]Token{
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .I32 = 1 },
        .{ .SeqEnd = {} },
    });
}

test "serialize - void" {
    try t({}, &[_]Token{.{ .Void = {} }});
}

fn t(v: anytype, tokens: []const Token) !void {
    var s = TestSerializer.init(tokens);

    serialize(v, s.serializer()) catch return error.TestUnexpectedError;
    try expect(s.remaining() == 0);
}

comptime {
    std.testing.refAllDecls(@This());
}
