//! Deserialization framework.
//!
//! Visually, deserialization in Getty can be represented like so:
//!
//!                  Zig data
//!
//!                     ▲          <-----------------------
//!                     |                                 |
//!                                                       |
//!              Getty Data Model                         |
//!                                                       |
//!                     ▲          <-------               |
//!                     |                 |               |
//!                                       |               |
//!                Data Format            |               |
//!                                       |               |
//!                                       |
//!                                       |      Deserialization Block
//!                                       |
//!
//!                               `getty.Deserializer`
//!
//! Data Model
//! ==========
//!
//! The Getty Data Model (GDM) is the set of types supported by Getty. The
//! types within the GDM are purely conceptual; they aren't actual Zig types.
//! For example, there is no `i32` or `u64` in the GDM. Instead, they are both
//! considered to be the type: integer.
//!
//! By maintaining a data model, Getty establishes a generic baseline from
//! which deserializers can operate. This often simplifies the job of a
//! deserializer significantly. For example, Zig considers `struct { x: i32 }`
//! and `struct { y: bool }` to be different types. However, in Getty they are
//! both considered to be the same type: struct. This means that if a
//! deserializer knows how to deserialize into a struct (as defined by the
//! GDM), then it will be able to deserialize into `struct { x: i32 }` values,
//! `struct { y: bool }` values, and values of any other struct type that is
//! composed of data types supported by Getty.
//!
//! The deserialization GDM consists of the following types:
//!
//!   1. Boolean
//!   2. Enum
//!   3. Float
//!   4. Integer
//!   5. Map
//!   6. Optional
//!   7. Sequence
//!   8. String
//!   9. Struct
//!   10. Void
//!
//! Deserializers
//! =============
//!
//! A deserializer is an implementation of the `getty.Deserializer` interface.
//! They define the conversion process between an input data format (e.g.,
//! JSON, YAML) and Getty's data model. For example, a JSON deserializer would
//! be responsible for converting JSON maps into Getty maps.
//!
//! Deserialization Blocks
//! ======================
//!
//! Deserialization Blocks (DB) make up the core of custom deserialization in
//! Getty. DBs define how to deserialize into values of one or more types.
//!
//! A DB is a struct namespace containing three functions:
//!
//!   1. fn is(comptime T: type) bool
//!   2. fn deserialize(comptime T: type, deserializer: anytype, visitor: anytype) @TypeOf(deserializer).Error!@TypeOf(visitor).Value
//!   3. fn visitor(allocator: ?std.mem.Allocator, comptime T: type) ...
//!
//! The `is` function specifies which types are deserializable by the DB. The
//! `deserialize` defines how to deserialize the input data format into Getty's
//! data model. Finally, the `visitor` function returns an instance of an
//! implementation of the `getty.de.Visitor` interface, which Getty will use to
//! produce an actual Zig value.
//!
//! For example, the following shows a DB for booleans. With it, you can
//! deserialize into a `bool` from a JSON boolean or a JSON integer:
//!
//! ```zig
//! const bool_db = struct {
//!     pub fn is(comptime T: type) bool {
//!         return T == bool;
//!     }
//!
//!     pub fn deserialize(comptime _: anytype, deserializer: anytype, v: anytype) !@TypeOf(v).Value {
//!         return try deserializer.deserializeBool(v);
//!     }
//!
//!     pub fn visitor(_: ?std.mem.Allocator, comptime _: type) Visitor {
//!         return .{};
//!     }
//!
//!     const Visitor = struct {
//!         pub usingnamespace getty.de.Visitor(
//!             @This(),
//!             bool,
//!             visitBool,
//!             undefined,
//!             undefined,
//!             visitInt,
//!             undefined,
//!             undefined,
//!             undefined,
//!             undefined,
//!             undefined,
//!             undefined,
//!         );
//!
//!         pub fn visitBool(_: @This(), comptime _: type, input: bool) !bool {
//!             return input;
//!         }
//!
//!         pub fn visitInt(_: @This(), comptime _: type, input: anytype) !bool {
//!             return input > 0;
//!         }
//!     };
//! };
//! ```
//!
//! Deserialization Tuples
//! ======================
//!
//! DBs can be grouped up into a tuple, known as a Deserialization Tuple (DT).
//!
//! Getty provides its own DT for various Zig data types, but users and
//! deserializers can provide their own through the `getty.Deserializer`
//! interface.

const std = @import("std");

/// Deserializer interface.
pub const Deserializer = @import("de/interfaces/deserializer.zig").Deserializer;

/// The default Deserialization Tuple.
///
/// If a user or deserializer DT is provided, the default DT is appended to the
/// end, thereby taking the lowest priority.
pub const default_dt = .{
    // std
    de.blocks.ArrayList,
    de.blocks.HashMap,
    de.blocks.LinkedList,
    de.blocks.TailQueue,

    // primitives
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

/// Compile-time type restraints for various deserialization-specific Getty data types.
pub const concepts = struct {
    pub usingnamespace @import("de/concepts/dbt.zig");
    pub usingnamespace @import("de/concepts/deserializer.zig");
    pub usingnamespace @import("de/concepts/map_access.zig");
    pub usingnamespace @import("de/concepts/seed.zig");
    pub usingnamespace @import("de/concepts/seq_access.zig");
    pub usingnamespace @import("de/concepts/union_access.zig");
    pub usingnamespace @import("de/concepts/variant_access.zig");
    pub usingnamespace @import("de/concepts/visitor.zig");
};

pub const traits = struct {
    pub usingnamespace @import("de/traits/dbt.zig");
};

/// Namespace for deserialization-specific types and functions.
pub const de = struct {
    /// Generic error set for `getty.de.Visitor` implementations.
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

    /// Map access and deserialization interface.
    pub usingnamespace @import("de/interfaces/map_access.zig");

    /// Deserialization seed interface.
    pub usingnamespace @import("de/interfaces/seed.zig");

    /// Sequence access and deserialization interface.
    pub usingnamespace @import("de/interfaces/seq_access.zig");

    /// Union access and deserialization interface.
    pub usingnamespace @import("de/interfaces/union_access.zig");

    /// Variant access and deserialization interface.
    pub usingnamespace @import("de/interfaces/variant_access.zig");

    /// Visitor interface.
    pub usingnamespace @import("de/interfaces/visitor.zig");

    /// Default deserialization seed implementation.
    pub usingnamespace @import("de/impls/seed/default.zig");

    /// Frees resources allocated during Getty deserialization.
    pub fn free(allocator: std.mem.Allocator, value: anytype) void {
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
        // std
        pub const ArrayList = @import("de/blocks/array_list.zig");
        pub const HashMap = @import("de/blocks/hash_map.zig");
        pub const LinkedList = @import("de/blocks/linked_list.zig");
        pub const TailQueue = @import("de/blocks/tail_queue.zig");

        // primitives
        pub const Array = @import("de/blocks/array.zig");
        pub const Bool = @import("de/blocks/bool.zig");
        pub const Enum = @import("de/blocks/enum.zig");
        pub const Float = @import("de/blocks/float.zig");
        pub const Int = @import("de/blocks/int.zig");
        pub const Optional = @import("de/blocks/optional.zig");
        pub const Pointer = @import("de/blocks/pointer.zig");
        pub const Slice = @import("de/blocks/slice.zig");
        pub const Struct = @import("de/blocks/struct.zig");
        pub const Tuple = @import("de/blocks/tuple.zig");
        pub const Union = @import("de/blocks/union.zig");
        pub const Void = @import("de/blocks/void.zig");
    };

    /// Returns the highest priority Deserialization Block for a type given a
    /// deserializer type.
    pub fn find_db(comptime De: type, comptime T: type) type {
        comptime {
            concepts.@"getty.Deserializer"(De);

            // Check user DBTs.
            inline for (De.user_dt) |db| {
                if (db.is(T)) {
                    return db;
                }
            }

            // Check type DBTs.
            if (std.meta.trait.isContainer(T) and
                std.meta.trait.hasDecls(T, .{"getty.dbt"}) and
                traits.is_dbt(T.@"getty.dbt"))
            {
                const type_dbt = T.@"getty.dbt";
                const type_tuple = if (@TypeOf(type_dbt) == type) .{type_dbt} else type_dbt;

                inline for (type_tuple) |db| {
                    if (db.is(T)) {
                        return db;
                    }
                }
            }

            // Check deserializer DBTs.
            inline for (De.deserializer_dt) |db| {
                if (db.is(T)) {
                    return db;
                }
            }

            // Check default DBTs.
            inline for (default_dt) |db| {
                if (db.is(T)) {
                    return db;
                }
            }

            @compileError(std.fmt.comptimePrint("type `{s}` is not supported", .{@typeName(T)}));
        }
    }
};

/// Deserializes a value from the given Getty deserializer.
pub fn deserialize(allocator: ?std.mem.Allocator, comptime T: type, deserializer: anytype) blk: {
    const D = @TypeOf(deserializer);

    concepts.@"getty.Deserializer"(D);

    break :blk D.Error!T;
} {
    const db = de.find_db(@TypeOf(deserializer), T);
    var v = db.Visitor(T){};

    return try deserializeInternal(allocator, T, deserializer, v.visitor());
}

fn deserializeInternal(allocator: ?std.mem.Allocator, comptime T: type, deserializer: anytype, visitor: anytype) blk: {
    const D = @TypeOf(deserializer);
    const V = @TypeOf(visitor);

    concepts.@"getty.Deserializer"(D);
    concepts.@"getty.de.Visitor"(V);

    break :blk D.Error!V.Value;
} {
    const db = de.find_db(@TypeOf(deserializer), T);

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
        deserializeBool,
        deserializeEnum,
        deserializeFloat,
        deserializeInt,
        deserializeMap,
        deserializeOptional,
        deserializeSeq,
        deserializeString,
        deserializeStruct,
        deserializeUnion,
        deserializeVoid,
    );

    const Error = de.Error || error{TestExpectedEqual};

    fn deserializeBool(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Bool => |v| return try visitor.visitBool(allocator, Self.@"getty.Deserializer", v),
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeEnum(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Enum => switch (self.nextToken()) {
                .U8 => |v| return try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
                .U16 => |v| return try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
                .U32 => |v| return try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
                .U64 => |v| return try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
                .U128 => |v| return try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
                .String => |v| return try visitor.visitString(allocator, Self.@"getty.Deserializer", v),
                else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
            },
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeFloat(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        return switch (self.nextToken()) {
            .F16 => |v| try visitor.visitFloat(allocator, Self.@"getty.Deserializer", v),
            .F32 => |v| try visitor.visitFloat(allocator, Self.@"getty.Deserializer", v),
            .F64 => |v| try visitor.visitFloat(allocator, Self.@"getty.Deserializer", v),
            .F128 => |v| try visitor.visitFloat(allocator, Self.@"getty.Deserializer", v),
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        };
    }

    fn deserializeInt(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        return switch (self.nextToken()) {
            .I8 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .I16 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .I32 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .I64 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .I128 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .U8 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .U16 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .U32 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .U64 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            .U128 => |v| try visitor.visitInt(allocator, Self.@"getty.Deserializer", v),
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        };
    }

    fn deserializeMap(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Map => |v| {
                var m = Map{ .de = self, .len = v.len, .end = .MapEnd };
                var value = visitor.visitMap(allocator, Self.@"getty.Deserializer", m.mapAccess());

                try self.assertNextToken(.MapEnd);

                return value;
            },
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeOptional(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.peekToken()) {
            .Null => {
                _ = self.nextToken();
                return try visitor.visitNull(allocator, Self.@"getty.Deserializer");
            },
            .Some => {
                _ = self.nextToken();
                return try visitor.visitSome(allocator, self.deserializer());
            },
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeSeq(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Seq => |v| {
                var s = Seq{ .de = self, .len = v.len, .end = .SeqEnd };
                var value = visitor.visitSeq(allocator, Self.@"getty.Deserializer", s.seqAccess());

                try self.assertNextToken(.SeqEnd);

                return value;
            },
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeString(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .String => |v| return try visitor.visitString(allocator, Self.@"getty.Deserializer", v),
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeStruct(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Struct => |v| {
                var s = Struct{ .de = self, .len = v.len, .end = .StructEnd };
                var value = visitor.visitMap(allocator, Self.@"getty.Deserializer", s.mapAccess());

                try self.assertNextToken(.StructEnd);

                return value;
            },
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeUnion(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Union => {
                var u = Union{ .de = self };
                return visitor.visitUnion(allocator, Self.@"getty.Deserializer", u.unionAccess(), u.variantAccess());
            },
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
    }

    fn deserializeVoid(self: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
        switch (self.nextToken()) {
            .Void => return try visitor.visitVoid(allocator, Self.@"getty.Deserializer"),
            else => |v| std.debug.panic("deserialization did not expect this token: {s}", .{@tagName(v)}),
        }
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
            nextElementSeed,
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
            nextKeySeed,
            nextValueSeed,
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
            nextKeySeed,
            nextValueSeed,
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
    };

    const Union = struct {
        de: *TestDeserializer,

        pub usingnamespace de.UnionAccess(
            *Union,
            Error,
            variantSeed,
        );

        pub usingnamespace de.VariantAccess(
            *Union,
            Error,
            payloadSeed,
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
    const v = deserialize(test_allocator, T, d.deserializer()) catch return error.TestUnexpectedError;
    defer de.free(test_allocator, v);

    switch (@typeInfo(T)) {
        .Bool,
        .Float,
        .Int,
        .Void,
        .Enum,
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
