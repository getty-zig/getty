//! Deserialization framework.

const std = @import("std");

/// Deserializer interface.
pub const Deserializer = @import("de/interfaces/deserializer.zig").Deserializer;

pub const default_dt = .{
    ////////////////////////////////////////////////////////////////////////////
    // Standard Library
    ////////////////////////////////////////////////////////////////////////////

    de.blocks.ArrayList,
    de.blocks.BufMap,
    de.blocks.HashMap,
    de.blocks.LinkedList,
    de.blocks.TailQueue,

    ////////////////////////////////////////////////////////////////////////////
    // User-Defined
    ////////////////////////////////////////////////////////////////////////////

    de.blocks.Ignored,

    ////////////////////////////////////////////////////////////////////////////
    // Primitives
    ////////////////////////////////////////////////////////////////////////////

    de.blocks.Array,
    de.blocks.Bool,
    de.blocks.Enum,
    de.blocks.Float,
    de.blocks.Int,
    de.blocks.Optional,
    de.blocks.Pointer,
    de.blocks.Slice,
    de.blocks.Struct,
    de.blocks.Tuple,
    de.blocks.Union,
    de.blocks.Void,
};

pub const concepts = struct {
    pub usingnamespace @import("de/concepts/block.zig");
    pub usingnamespace @import("de/concepts/deserializer.zig");
    pub usingnamespace @import("de/concepts/map_access.zig");
    pub usingnamespace @import("de/concepts/seed.zig");
    pub usingnamespace @import("de/concepts/seq_access.zig");
    pub usingnamespace @import("de/concepts/union_access.zig");
    pub usingnamespace @import("de/concepts/variant_access.zig");
    pub usingnamespace @import("de/concepts/visitor.zig");
};

pub const traits = struct {
    pub usingnamespace @import("de/traits/block.zig");
    pub usingnamespace @import("de/traits/attributes.zig");
};

/// Namespace for deserialization-specific types and functions.
pub const de = struct {
    /// A generic error set for `getty.Deserializer` implementations.
    ///
    /// This error set must always be included in a `getty.Deserializer`
    /// implementation's error set.
    pub const Error = std.mem.Allocator.Error || error{
        DuplicateField,
        InvalidLength,
        InvalidType,
        InvalidValue,
        MissingField,
        MissingVariant,
        UnknownField,
        UnknownVariant,
        Unsupported,
    };

    pub const MapAccess = @import("de/interfaces/map_access.zig").MapAccess;
    pub const SeqAccess = @import("de/interfaces/seq_access.zig").SeqAccess;
    pub const UnionAccess = @import("de/interfaces/union_access.zig").UnionAccess;
    pub const VariantAccess = @import("de/interfaces/variant_access.zig").VariantAccess;

    pub const Visitor = @import("de/interfaces/visitor.zig").Visitor;

    pub const Seed = @import("de/interfaces/seed.zig").Seed;
    pub const DefaultSeed = @import("de/impls/seed/default.zig").DefaultSeed;

    pub const Ignored = @import("de/impls/ignored.zig").Ignored;

    /// Frees resources allocated during Getty deserialization.
    ///
    /// Values that cannot be deallocated, such as `bool` values, are ignored.
    pub fn free(
        /// A memory allocator.
        allocator: std.mem.Allocator,
        /// A value to deallocate.
        value: anytype,
    ) void {
        const T = @TypeOf(value);
        const name = @typeName(T);

        switch (@typeInfo(T)) {
            .AnyFrame, .Bool, .Float, .ComptimeFloat, .Int, .ComptimeInt, .Enum, .EnumLiteral, .Fn, .Null, .Opaque, .Frame, .Void => {},
            .Array => for (value) |v| free(allocator, v),
            .Optional => if (value) |v| free(allocator, v),
            .Pointer => |info| switch (comptime std.meta.trait.isZigString(T)) {
                true => allocator.free(value),
                false => switch (info.size) {
                    .One => {
                        // Trying to free `anyopaque` or `fn` values here
                        // triggers the errors in the following issue:
                        //
                        //   https://github.com/getty-zig/getty/issues/37.
                        switch (@typeInfo(info.child)) {
                            .Fn, .Opaque => return,
                            else => {
                                free(allocator, value.*);
                                allocator.destroy(value);
                            },
                        }
                    },
                    .Slice => {
                        for (value) |v| free(allocator, v);
                        allocator.free(value);
                    },
                    else => unreachable,
                },
            },
            .Union => |info| if (info.tag_type) |Tag| {
                inline for (info.fields) |field| {
                    if (value == @field(Tag, field.name)) {
                        free(allocator, @field(value, field.name));
                        break;
                    }
                }
            },
            .Struct => |info| {
                if (comptime std.mem.startsWith(u8, name, "array_list.ArrayListAlignedUnmanaged")) {
                    for (value.items) |v| free(allocator, v);
                    var mut = value;
                    mut.deinit(allocator);
                } else if (comptime std.mem.startsWith(u8, name, "array_list.ArrayList")) {
                    for (value.items) |v| free(allocator, v);
                    value.deinit();
                } else if (T == std.BufMap) {
                    var it = value.hash_map.iterator();
                    while (it.next()) |entry| {
                        free(allocator, entry.key_ptr.*);
                        free(allocator, entry.value_ptr.*);
                    }
                    var mut = value;
                    mut.hash_map.deinit();
                } else if (comptime std.mem.startsWith(u8, name, "hash_map.HashMapUnmanaged")) {
                    var iterator = value.iterator();
                    while (iterator.next()) |entry| {
                        free(allocator, entry.key_ptr.*);
                        free(allocator, entry.value_ptr.*);
                    }
                    var mut = value;
                    mut.deinit(allocator);
                } else if (comptime std.mem.startsWith(u8, name, "hash_map.HashMap")) {
                    var iterator = value.iterator();
                    while (iterator.next()) |entry| {
                        free(allocator, entry.key_ptr.*);
                        free(allocator, entry.value_ptr.*);
                    }
                    var mut = value;
                    mut.deinit();
                } else if (comptime std.mem.startsWith(u8, name, "linked_list")) {
                    var iterator = value.first;
                    while (iterator) |node| {
                        free(allocator, node.data);
                        iterator = node.next;
                        allocator.destroy(node);
                    }
                } else {
                    inline for (info.fields) |field| {
                        if (!field.is_comptime) free(allocator, @field(value, field.name));
                    }
                }
            },
            else => unreachable,
        }
    }

    pub const blocks = struct {
        ////////////////////////////////////////////////////////////////////////
        // Standard Library
        ////////////////////////////////////////////////////////////////////////

        /// Deserialization block for `std.ArrayList` values.
        pub const ArrayList = @import("de/blocks/array_list.zig");

        /// Deserialization block for `std.BufMap` values.
        pub const BufMap = @import("de/blocks/buf_map.zig");

        /// Deserialization block for `std.HashMap` values.
        pub const HashMap = @import("de/blocks/hash_map.zig");

        /// Deserialization block for `std.SinglyLinkedList` values.
        pub const LinkedList = @import("de/blocks/linked_list.zig");

        /// Deserialization block for `std.TailQueue`.
        pub const TailQueue = @import("de/blocks/tail_queue.zig");

        ////////////////////////////////////////////////////////////////////////
        // User-Defined
        ////////////////////////////////////////////////////////////////////////

        pub const Ignored = @import("de/blocks/ignored.zig");

        ////////////////////////////////////////////////////////////////////////
        // Primitives
        ////////////////////////////////////////////////////////////////////////

        /// Deserializaton block for array values.
        pub const Array = @import("de/blocks/array.zig");

        /// Deserialization block for `bool` values.
        pub const Bool = @import("de/blocks/bool.zig");

        /// Deserialization block for `enum` values.
        pub const Enum = @import("de/blocks/enum.zig");

        /// Deserialization block for floating-point values.
        pub const Float = @import("de/blocks/float.zig");

        /// Deserialization block for integer values.
        pub const Int = @import("de/blocks/int.zig");

        /// Deserialization block for optional values.
        pub const Optional = @import("de/blocks/optional.zig");

        /// Deserialization block for pointer values.
        pub const Pointer = @import("de/blocks/pointer.zig");

        /// Deserialization block for slice values.
        pub const Slice = @import("de/blocks/slice.zig");

        /// Deserialization block for `struct` values.
        pub const Struct = @import("de/blocks/struct.zig");

        /// Deserialization block for tuple values.
        pub const Tuple = @import("de/blocks/tuple.zig");

        /// Deserialization block for `union` values.
        pub const Union = @import("de/blocks/union.zig");

        /// Deserialization block for `void` values.
        pub const Void = @import("de/blocks/void.zig");
    };

    /// Returns the attributes for a type. If none exists, `null` is returned.
    pub fn getAttributes(
        /// A type with attributes.
        comptime T: type,
        /// A `getty.Deserializer` interface type.
        comptime D: type,
    ) blk: {
        // Process user DBs.
        for (D.user_dt) |db| {
            if (db.is(T) and traits.has_attributes(T, db)) {
                break :blk ?@TypeOf(db.attributes);
            }
        }

        // Process type DBs.
        if (traits.has_db(T)) {
            const db = T.@"getty.db";

            if (traits.has_attributes(T, db)) {
                break :blk ?@TypeOf(db.attributes);
            }
        }

        break :blk ?void;
    } {
        comptime {
            // Process user DBTs.
            for (D.user_dt) |db| {
                if (db.is(T) and traits.has_attributes(T, db)) {
                    return @as(?@TypeOf(db.attributes), db.attributes);
                }
            }

            // Process type DBTs.
            if (traits.has_db(T)) {
                const db = T.@"getty.db";

                if (traits.has_attributes(T, db)) {
                    return @as(?@TypeOf(db.attributes), db.attributes);
                }
            }

            return null;
        }
    }

    // TODO: Swap function parameters.
    /// Returns the highest priority Deserialization Block for a type.
    pub fn find_db(
        /// A `getty.Deserializer` interface type.
        comptime D: type,
        /// The type being deserialized into.
        comptime T: type,
    ) type {
        comptime {
            concepts.@"getty.Deserializer"(D);

            // Process user DBs.
            for (D.user_dt) |db| {
                if (db.is(T)) {
                    return db;
                }
            }

            // Process type DBs.
            if (traits.has_db(T)) {
                return T.@"getty.db";
            }

            // Process deserializer DBs.
            for (D.deserializer_dt) |db| {
                if (db.is(T)) {
                    return db;
                }
            }

            // Process default DBs.
            for (default_dt) |db| {
                if (db.is(T)) {
                    return db;
                }
            }

            @compileError("type is not supported: " ++ @typeName(T));
        }
    }
};

/// Deserializes a value.
pub fn deserialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// The type to deserialize into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
) blk: {
    const D = @TypeOf(deserializer);

    concepts.@"getty.Deserializer"(D);

    break :blk D.Error!T;
} {
    const db = comptime de.find_db(@TypeOf(deserializer), T);

    var v = blk: {
        if (comptime traits.has_attributes(T, db)) {
            break :blk switch (@typeInfo(T)) {
                .Struct => de.blocks.Struct.Visitor(T){},
                .Enum => de.blocks.Enum.Visitor(T){},
                .Union => de.blocks.Union.Visitor(T){},
                else => @compileError("unexpected type cannot be deserialized using attributes"),
            };
        }

        break :blk db.Visitor(T){};
    };

    return try deserializeInternal(allocator, T, deserializer, v.visitor());
}

fn deserializeInternal(allocator: ?std.mem.Allocator, comptime T: type, deserializer: anytype, visitor: anytype) blk: {
    const D = @TypeOf(deserializer);
    const V = @TypeOf(visitor);

    concepts.@"getty.Deserializer"(D);
    concepts.@"getty.de.Visitor"(V);

    break :blk D.Error!V.Value;
} {
    const db = comptime de.find_db(@TypeOf(deserializer), T);

    if (comptime traits.has_attributes(T, db)) {
        switch (@typeInfo(T)) {
            .Struct => return try de.blocks.Struct.deserialize(allocator, T, deserializer, visitor),
            .Enum => return try de.blocks.Enum.deserialize(allocator, T, deserializer, visitor),
            .Union => return try de.blocks.Union.deserialize(allocator, T, deserializer, visitor),
            else => @compileError("unexpected type cannot be deserialized using attributes"),
        }
    }

    return try db.deserialize(allocator, T, deserializer, visitor);
}

const Token = @import("tests/common.zig").Token;

const testing = std.testing;

const test_allocator = testing.allocator;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectEqualSlices = testing.expectEqualSlices;
const expectEqualStrings = testing.expectEqualStrings;

const TestDeserializer = struct {
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

    pub fn nextToken(self: *Self) Token {
        switch (self.remaining()) {
            0 => std.debug.panic("ran out of tokens to deserialize", .{}),
            else => |len| {
                const first = self.tokens[0];
                self.tokens = if (len == 1) &[_]Token{} else self.tokens[1..];
                return first;
            },
        }
    }

    fn peekTokenOpt(self: Self) ?Token {
        return if (self.tokens.len > 0) self.tokens[0] else null;
    }

    fn peekToken(self: Self) Token {
        if (self.peekTokenOpt()) |token| {
            return token;
        } else {
            std.debug.panic("ran out of tokens to deserialize", .{});
        }
    }

    pub usingnamespace Deserializer(
        *Self,
        Error,
        default_dt,
        default_dt,
        .{
            .deserializeAny = deserializeAny,
            .deserializeBool = deserializeAny,
            .deserializeEnum = deserializeAny,
            .deserializeFloat = deserializeAny,
            .deserializeInt = deserializeAny,
            .deserializeMap = deserializeAny,
            .deserializeOptional = deserializeAny,
            .deserializeSeq = deserializeAny,
            .deserializeString = deserializeAny,
            .deserializeStruct = deserializeAny,
            .deserializeUnion = deserializeAny,
            .deserializeVoid = deserializeAny,
        },
    );

    const Error = de.Error || error{TestExpectedEqual};

    const De = Self.@"getty.Deserializer";

    fn deserializeAny(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        return switch (self.nextToken()) {
            .Bool => |v| try visitor.visitBool(allocator, De, v),
            .I8 => |v| try visitor.visitInt(allocator, De, v),
            .I16 => |v| try visitor.visitInt(allocator, De, v),
            .I32 => |v| try visitor.visitInt(allocator, De, v),
            .I64 => |v| try visitor.visitInt(allocator, De, v),
            .I128 => |v| try visitor.visitInt(allocator, De, v),
            .U8 => |v| try visitor.visitInt(allocator, De, v),
            .U16 => |v| try visitor.visitInt(allocator, De, v),
            .U32 => |v| try visitor.visitInt(allocator, De, v),
            .U64 => |v| try visitor.visitInt(allocator, De, v),
            .U128 => |v| try visitor.visitInt(allocator, De, v),
            .F16 => |v| try visitor.visitFloat(allocator, De, v),
            .F32 => |v| try visitor.visitFloat(allocator, De, v),
            .F64 => |v| try visitor.visitFloat(allocator, De, v),
            .F128 => |v| try visitor.visitFloat(allocator, De, v),
            .Enum => switch (self.nextToken()) {
                .U8 => |v| try visitor.visitInt(allocator, De, v),
                .U16 => |v| try visitor.visitInt(allocator, De, v),
                .U32 => |v| try visitor.visitInt(allocator, De, v),
                .U64 => |v| try visitor.visitInt(allocator, De, v),
                .U128 => |v| try visitor.visitInt(allocator, De, v),
                .String => |v| try visitor.visitString(allocator, De, v),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            },
            .Null => try visitor.visitNull(allocator, De),
            .Some => try visitor.visitSome(allocator, self.deserializer()),
            .String => |v| try visitor.visitString(allocator, De, v),
            .Void => try visitor.visitVoid(allocator, De),
            .Map => |v| blk: {
                var m = Map{ .de = self, .len = v.len, .end = .MapEnd };
                var value = try visitor.visitMap(allocator, De, m.mapAccess());

                try self.assertNextToken(.MapEnd);

                break :blk value;
            },
            .Seq => |v| blk: {
                var s = Seq{ .de = self, .len = v.len, .end = .SeqEnd };
                var value = try visitor.visitSeq(allocator, De, s.seqAccess());

                try self.assertNextToken(.SeqEnd);

                break :blk value;
            },
            .Struct => |v| blk: {
                var s = Struct{ .de = self, .len = v.len, .end = .StructEnd };
                var value = try visitor.visitMap(allocator, De, s.mapAccess());

                try self.assertNextToken(.StructEnd);

                break :blk value;
            },
            .Union => blk: {
                var u = Union{ .de = self };
                break :blk try visitor.visitUnion(allocator, De, u.unionAccess(), u.variantAccess());
            },

            // Panic! At The Disco
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        };
    }

    fn assertNextToken(self: *Self, expected: Token) !void {
        if (self.nextTokenOpt()) |token| {
            const token_tag = std.meta.activeTag(token);
            const expected_tag = std.meta.activeTag(expected);

            if (token_tag == expected_tag) {
                switch (token) {
                    .MapEnd => try expectEqual(@field(token, "MapEnd"), @field(expected, "MapEnd")),
                    .SeqEnd => try expectEqual(@field(token, "SeqEnd"), @field(expected, "SeqEnd")),
                    .StructEnd => try expectEqual(@field(token, "StructEnd"), @field(expected, "StructEnd")),
                    else => |v| std.debug.panic("unexpected token: {s}", .{@tagName(v)}),
                }
            } else {
                @panic("expected Token::{} but deserialization wants Token::{}");
            }
        } else {
            @panic("end of tokens but deserialization wants Token::{}");
        }
    }

    const Seq = struct {
        de: *TestDeserializer,
        len: ?usize,
        end: Token,

        pub usingnamespace de.SeqAccess(
            *Seq,
            Error,
            .{ .nextElementSeed = nextElementSeed },
        );

        fn nextElementSeed(self: *Seq, allocator: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
            if (self.de.peekTokenOpt()) |token| {
                if (std.meta.eql(token, self.end)) return null;
            }

            self.len.? -= @as(usize, if (self.len.? > 0) 1 else 0);

            return try seed.deserialize(allocator, self.de.deserializer());
        }
    };

    const Map = struct {
        de: *TestDeserializer,
        len: ?usize,
        end: Token,

        pub usingnamespace de.MapAccess(
            *Map,
            Error,
            .{
                .nextKeySeed = nextKeySeed,
                .nextValueSeed = nextValueSeed,
            },
        );

        fn nextKeySeed(self: *Map, allocator: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
            if (self.de.peekTokenOpt()) |token| {
                if (std.meta.eql(token, self.end)) return null;
            } else {
                return null;
            }

            self.len.? -= @as(usize, if (self.len.? > 0) 1 else 0);

            return try seed.deserialize(allocator, self.de.deserializer());
        }

        fn nextValueSeed(self: *Map, allocator: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
            return try seed.deserialize(allocator, self.de.deserializer());
        }
    };

    const Struct = struct {
        de: *TestDeserializer,
        len: ?usize,
        end: Token,

        pub usingnamespace de.MapAccess(
            *Struct,
            Error,
            .{
                .nextKeySeed = nextKeySeed,
                .nextValueSeed = nextValueSeed,
                .isKeyAllocated = isKeyAllocated,
            },
        );

        fn nextKeySeed(self: *Struct, _: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
            if (self.de.peekTokenOpt()) |token| {
                if (std.meta.eql(token, self.end)) return null;
            } else {
                return null;
            }

            if (self.de.nextTokenOpt()) |token| {
                self.len.? -= @as(usize, if (self.len.? > 0) 1 else 0);

                if (token != .String) {
                    return error.InvalidType;
                }

                return token.String;
            } else {
                return null;
            }
        }

        fn nextValueSeed(self: *Struct, allocator: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
            return try seed.deserialize(allocator, self.de.deserializer());
        }

        fn isKeyAllocated(_: *Struct, comptime _: type) bool {
            return false;
        }
    };

    const Union = struct {
        de: *TestDeserializer,

        pub usingnamespace de.UnionAccess(
            *Union,
            Error,
            .{ .variantSeed = variantSeed },
        );

        pub usingnamespace de.VariantAccess(
            *Union,
            Error,
            .{ .payloadSeed = payloadSeed },
        );

        fn variantSeed(self: *Union, _: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
            const token = self.de.nextToken();

            if (token == .String) {
                return token.String;
            }

            return error.InvalidType;
        }

        fn payloadSeed(self: *Union, allocator: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
            if (@TypeOf(seed).Value != void) {
                return try seed.deserialize(allocator, self.de.deserializer());
            }

            if (self.de.nextToken() != .Void) {
                return error.UnknownVariant;
            }
        }
    };
};

test "deserialize - array" {
    try t([_]i32{}, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });
    try t([3]i32{ 1, 2, 3 }, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = {} },
    });
    try t([3][2]i32{ .{ 1, 2 }, .{ 3, 4 }, .{ 5, 6 } }, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .SeqEnd = {} },
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 3 },
        .{ .I32 = 4 },
        .{ .SeqEnd = {} },
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 5 },
        .{ .I32 = 6 },
        .{ .SeqEnd = {} },
        .{ .SeqEnd = {} },
    });
}

test "deserialize - array list" {
    {
        var expected = std.ArrayList(void).init(test_allocator);
        defer expected.deinit();

        try t(expected, &[_]Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        });
    }

    {
        var expected = std.ArrayList(isize).init(test_allocator);
        defer expected.deinit();

        try expected.append(1);
        try expected.append(2);
        try expected.append(3);

        try t(expected, &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .I8 = 1 },
            .{ .I32 = 2 },
            .{ .I64 = 3 },
            .{ .SeqEnd = {} },
        });
    }

    {
        const Child = std.ArrayList(isize);
        const Parent = std.ArrayList(Child);

        var expected = Parent.init(test_allocator);
        var a = Child.init(test_allocator);
        var b = Child.init(test_allocator);
        var c = Child.init(test_allocator);
        defer {
            expected.deinit();
            a.deinit();
            b.deinit();
            c.deinit();
        }

        try b.append(1);
        try c.append(2);
        try c.append(3);
        try expected.append(a);
        try expected.append(b);
        try expected.append(c);

        const tokens = &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = {} },
            .{ .SeqEnd = {} },
        };

        // Test manually since the `t` function cannot recursively test
        // user-defined containers containers without ugly hacks.
        var d = TestDeserializer.init(tokens);
        const v = deserialize(test_allocator, Parent, d.deserializer()) catch return error.TestUnexpectedError;
        defer de.free(test_allocator, v);

        try expectEqual(expected.capacity, v.capacity);
        for (v.items) |l, i| {
            try expectEqual(expected.items[i].capacity, l.capacity);
            try expectEqualSlices(isize, expected.items[i].items, l.items);
        }
    }
}

test "deserialize - bool" {
    try t(true, &[_]Token{.{ .Bool = true }});
    try t(false, &[_]Token{.{ .Bool = false }});
}

test "deserialize - buf map" {
    {
        var expected = std.BufMap.init(test_allocator);
        defer expected.deinit();

        try t(expected, &[_]Token{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });
    }

    {
        var expected = std.BufMap.init(test_allocator);
        defer expected.deinit();

        try expected.put("one", "foo");
        try expected.put("two", "bar");
        try expected.put("three", "baz");

        try t(expected, &[_]Token{
            .{ .Map = .{ .len = 3 } },
            .{ .String = "one" },
            .{ .String = "foo" },
            .{ .String = "two" },
            .{ .String = "bar" },
            .{ .String = "three" },
            .{ .String = "baz" },
            .{ .MapEnd = {} },
        });
    }
}

test "deserialize - enum" {
    const T = enum { zero, one, two, three, four };

    try t(T.zero, &[_]Token{ .{ .Enum = {} }, .{ .U8 = 0 } });
    try t(T.one, &[_]Token{ .{ .Enum = {} }, .{ .U16 = 1 } });
    try t(T.two, &[_]Token{ .{ .Enum = {} }, .{ .U32 = 2 } });
    try t(T.three, &[_]Token{ .{ .Enum = {} }, .{ .U64 = 3 } });
    try t(T.four, &[_]Token{ .{ .Enum = {} }, .{ .U128 = 4 } });

    try t(T.zero, &[_]Token{ .{ .Enum = {} }, .{ .String = "zero" } });
    try t(T.four, &[_]Token{ .{ .Enum = {} }, .{ .String = "four" } });
}

test "deserialize - float" {
    try t(@as(f16, 0), &[_]Token{.{ .F16 = 0 }});
    try t(@as(f32, 0), &[_]Token{.{ .F32 = 0 }});
    try t(@as(f64, 0), &[_]Token{.{ .F64 = 0 }});
    try t(@as(f128, 0), &[_]Token{.{ .F64 = 0 }});
}

test "deserialize - integer" {
    // signed
    try t(@as(i8, 0), &[_]Token{.{ .I8 = 0 }});
    try t(@as(i16, 0), &[_]Token{.{ .I16 = 0 }});
    try t(@as(i32, 0), &[_]Token{.{ .I32 = 0 }});
    try t(@as(i64, 0), &[_]Token{.{ .I64 = 0 }});
    try t(@as(i128, 0), &[_]Token{.{ .I128 = 0 }});
    try t(@as(isize, 0), &[_]Token{.{ .I128 = 0 }});

    // unsigned
    try t(@as(u8, 0), &[_]Token{.{ .U8 = 0 }});
    try t(@as(u16, 0), &[_]Token{.{ .U16 = 0 }});
    try t(@as(u32, 0), &[_]Token{.{ .U32 = 0 }});
    try t(@as(u64, 0), &[_]Token{.{ .U64 = 0 }});
    try t(@as(u128, 0), &[_]Token{.{ .U128 = 0 }});
    try t(@as(usize, 0), &[_]Token{.{ .U128 = 0 }});
}

test "deserialize - linked list" {
    {
        var expected = std.SinglyLinkedList(i32){};

        try t(expected, &[_]Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        });
    }

    {
        var expected = std.SinglyLinkedList(i32){};
        var one = @TypeOf(expected).Node{ .data = 1 };
        var two = @TypeOf(expected).Node{ .data = 2 };
        var three = @TypeOf(expected).Node{ .data = 3 };

        expected.prepend(&one);
        one.insertAfter(&two);
        two.insertAfter(&three);

        try t(expected, &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = {} },
        });
    }

    {
        const Child = std.SinglyLinkedList(i32);
        const Parent = std.SinglyLinkedList(Child);

        var expected = Parent{};
        var a = Child{};
        var b = Child{};
        var c = Child{};

        var one = Child.Node{ .data = 1 };
        var two = Child.Node{ .data = 2 };
        var three = Child.Node{ .data = 3 };
        b.prepend(&one);
        c.prepend(&three);
        c.prepend(&two);

        expected.prepend(&Parent.Node{ .data = c });
        expected.prepend(&Parent.Node{ .data = b });
        expected.prepend(&Parent.Node{ .data = a });

        const tokens = &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = {} },
            .{ .SeqEnd = {} },
        };

        // Test manually since the `t` function cannot recursively test
        // user-defined containers containers without ugly hacks.
        var d = TestDeserializer.init(tokens);
        var v = deserialize(test_allocator, Parent, d.deserializer()) catch return error.TestUnexpectedError;
        defer de.free(test_allocator, v);

        try expectEqual(expected.len(), v.len());
        var iterator = expected.first;
        while (iterator) |node| : (iterator = node.next) {
            var got_node = v.popFirst();
            try expect(got_node != null);
            defer test_allocator.destroy(got_node.?);

            try expectEqual(node.data.len(), got_node.?.data.len());
            var inner_iterator = node.data.first;
            while (inner_iterator) |inner_node| : (inner_iterator = inner_node.next) {
                var got_inner_node = got_node.?.data.popFirst();
                try expect(got_inner_node != null);
                defer test_allocator.destroy(got_inner_node.?);

                try expectEqual(inner_node.data, got_inner_node.?.data);
            }
        }
    }
}

test "deserialize - optional" {
    try t(@as(?i32, null), &[_]Token{.{ .Null = {} }});
    try t(@as(?i32, 0), &[_]Token{ .{ .Some = {} }, .{ .I32 = 0 } });
}

test "deserialize - string" {
    {
        var arr = [_]u8{ 'a', 'b', 'c' };

        // No sentinel
        try t("abc", &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .U8 = 'a' },
            .{ .U8 = 'b' },
            .{ .U8 = 'c' },
            .{ .SeqEnd = {} },
        });

        try t(@as([]u8, &arr), &[_]Token{.{ .String = "abc" }});
        try t(@as([]const u8, &arr), &[_]Token{.{ .String = "abc" }});
    }

    {
        var arr = [_:0]u8{ 'a', 'b', 'c' };

        // Sentinel
        try t("abc", &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .U8 = 'a' },
            .{ .U8 = 'b' },
            .{ .U8 = 'c' },
            .{ .SeqEnd = {} },
        });

        try t(@as([:0]u8, &arr), &[_]Token{.{ .String = "abc" }});
        try t(@as([:0]const u8, &arr), &[_]Token{.{ .String = "abc" }});
    }
}

test "deserialize - struct" {
    try t(struct {}{}, &[_]Token{
        .{ .Struct = .{ .name = "", .len = 0 } },
        .{ .StructEnd = {} },
    });

    const T = struct { a: i32, b: i32, c: i32 };

    try t(T{ .a = 1, .b = 2, .c = 3 }, &[_]Token{
        .{ .Struct = .{ .name = "T", .len = 3 } },
        .{ .String = "a" },
        .{ .I32 = 1 },
        .{ .String = "b" },
        .{ .I32 = 2 },
        .{ .String = "c" },
        .{ .I32 = 3 },
        .{ .StructEnd = {} },
    });
}

test "deserialize - tail queue" {
    {
        var expected = std.TailQueue(i32){};

        try t(expected, &[_]Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        });
    }

    {
        var expected = std.TailQueue(i32){};
        var one = @TypeOf(expected).Node{ .data = 1 };
        var two = @TypeOf(expected).Node{ .data = 2 };
        var three = @TypeOf(expected).Node{ .data = 3 };

        expected.append(&one);
        expected.append(&two);
        expected.append(&three);

        try t(expected, &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = {} },
        });
    }

    {
        const Child = std.TailQueue(i32);
        const Parent = std.TailQueue(Child);

        var expected = Parent{};
        var a = Child{};
        var b = Child{};
        var c = Child{};

        var one = Child.Node{ .data = 1 };
        var two = Child.Node{ .data = 2 };
        var three = Child.Node{ .data = 3 };
        b.append(&one);
        c.append(&two);
        c.append(&three);

        expected.append(&Parent.Node{ .data = a });
        expected.append(&Parent.Node{ .data = b });
        expected.append(&Parent.Node{ .data = c });

        const tokens = &[_]Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = {} },
            .{ .SeqEnd = {} },
        };

        // Test manually since the `t` function cannot recursively test
        // user-defined containers containers without ugly hacks.
        var d = TestDeserializer.init(tokens);
        var v = deserialize(test_allocator, Parent, d.deserializer()) catch return error.TestUnexpectedError;
        defer de.free(test_allocator, v);

        try expectEqual(expected.len, v.len);
        var iterator = expected.first;
        while (iterator) |node| : (iterator = node.next) {
            var got_node = v.popFirst();
            try expect(got_node != null);
            defer test_allocator.destroy(got_node.?);

            try expectEqual(node.data.len, got_node.?.data.len);
            var inner_iterator = node.data.first;
            while (inner_iterator) |inner_node| : (inner_iterator = inner_node.next) {
                var got_inner_node = got_node.?.data.popFirst();
                try expect(got_inner_node != null);
                defer test_allocator.destroy(got_inner_node.?);

                try expectEqual(inner_node.data, got_inner_node.?.data);
            }
        }
    }
}

test "deserialize - tuple" {
    try t(std.meta.Tuple(&[_]type{ i32, u32 }){ 1, 2 }, &[_]Token{
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .U32 = 2 },
        .{ .SeqEnd = {} },
    });

    //try t(std.meta.Tuple(&[_]type{
    //std.meta.Tuple(&[_]type{ i32, i32 }),
    //std.meta.Tuple(&[_]type{ i32, i32 }),
    //std.meta.Tuple(&[_]type{ i32, i32 }),
    //}){ .{ 1, 2 }, .{ 3, 4 }, .{ 5, 6 } }, &[_]Token{
    //.{ .Seq = .{ .len = 3 } },
    //.{ .Seq = .{ .len = 2 } },
    //.{ .I32 = 1 },
    //.{ .I32 = 2 },
    //.{ .SeqEnd = {} },
    //.{ .Seq = .{ .len = 2 } },
    //.{ .I32 = 3 },
    //.{ .I32 = 4 },
    //.{ .SeqEnd = {} },
    //.{ .Seq = .{ .len = 2 } },
    //.{ .I32 = 5 },
    //.{ .I32 = 6 },
    //.{ .SeqEnd = {} },
    //.{ .SeqEnd = {} },
    //});
}

test "deserialize - union" {
    // Tagged
    {
        const T = union(enum) {
            foo: bool,
            bar: void,
        };

        try t(T{ .foo = true }, &[_]Token{
            .{ .Union = {} },
            .{ .String = "foo" },
            .{ .Bool = true },
        });
        try t(T{ .bar = {} }, &[_]Token{
            .{ .Union = {} },
            .{ .String = "bar" },
            .{ .Void = {} },
        });
    }

    // Untagged
    {
        const T = union {
            foo: bool,
            bar: void,
        };

        {
            const tokens = &[_]Token{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Bool = true },
            };

            var d = TestDeserializer.init(tokens);
            const v = deserialize(test_allocator, T, d.deserializer()) catch return error.TestUnexpectedError;

            try expectEqual(true, v.foo);
        }

        {
            const tokens = &[_]Token{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Void = {} },
            };

            var d = TestDeserializer.init(tokens);
            const v = deserialize(test_allocator, T, d.deserializer()) catch return error.TestUnexpectedError;

            try expectEqual({}, v.bar);
        }
    }
}

test "deserialize - void" {
    try t({}, &[_]Token{.{ .Void = {} }});
}

/// This test function does not support:
///
/// - Untagged unions
/// - Recursive, user-defined containers (e.g., std.ArrayList(std.ArrayList(u8))).
fn t(expected: anytype, tokens: []const Token) !void {
    const T = @TypeOf(expected);

    var d = TestDeserializer.init(tokens);
    var v = deserialize(test_allocator, T, d.deserializer()) catch return error.TestUnexpectedError;
    defer de.free(test_allocator, v);

    switch (@typeInfo(T)) {
        .Bool,
        .Enum,
        .Float,
        .Int,
        .Optional,
        .Void,
        => try expectEqual(expected, v),
        .Array => |info| try expectEqualSlices(info.child, &expected, &v),
        .Pointer => |info| switch (comptime std.meta.trait.isZigString(T)) {
            true => try expectEqualStrings(expected, v),
            false => switch (info.size) {
                //.One => ,
                .Slice => try expectEqualSlices(info.child, expected, v),
                else => unreachable,
            },
        },
        .Struct => |info| {
            if (comptime std.mem.startsWith(u8, @typeName(T), "array_list")) {
                try expectEqual(expected.capacity, v.capacity);
                try expectEqualSlices(std.meta.Child(T.Slice), expected.items, v.items);
            } else if (comptime std.mem.startsWith(u8, @typeName(T), "linked_list.SinglyLinkedList")) {
                try expectEqual(expected.len(), v.len());
                var iterator = expected.first;

                while (iterator) |node| : (iterator = node.next) {
                    var got_node = v.popFirst();
                    try expect(got_node != null);
                    defer test_allocator.destroy(got_node.?);

                    try expectEqual(node.data, got_node.?.data);
                }
            } else if (comptime std.mem.startsWith(u8, @typeName(T), "linked_list.TailQueue")) {
                try expectEqual(expected.len, v.len);
                var iterator = expected.first;

                while (iterator) |node| : (iterator = node.next) {
                    var got_node = v.popFirst();
                    try expect(got_node != null);
                    defer test_allocator.destroy(got_node.?);

                    try expectEqual(node.data, got_node.?.data);
                }
            } else if (T == std.BufMap) {
                try expectEqual(expected.count(), v.count());

                var it = expected.iterator();
                while (it.next()) |kv| {
                    try expectEqualSlices(u8, expected.get(kv.key_ptr.*).?, v.get(kv.key_ptr.*).?);
                }
            } else switch (info.is_tuple) {
                true => {
                    const length = std.meta.fields(T).len;
                    comptime var i: usize = 0;

                    inline while (i < length) : (i += 1) {
                        try expectEqual(expected[i], v[i]);
                    }
                },
                false => try expectEqual(expected, v),
            }
        },
        .Union => |info| {
            if (info.tag_type == null) {
                @compileError("untagged unions are not supported by this function");
            }

            try expectEqual(expected, v);
        },
        else => unreachable,
    }

    try expect(d.remaining() == 0);
}

comptime {
    std.testing.refAllDecls(@This());
}
