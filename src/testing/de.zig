const builtin = @import("builtin");
const std = @import("std");
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectEqualStrings = std.testing.expectEqualStrings;

const getty = @import("getty");
const Token = @import("token.zig").Token;

// The type signature of a DB's `deserialize` function.
const DeserializeFn = @TypeOf(struct {
    fn f(
        _: ?std.mem.Allocator,
        comptime _: type,
        deserializer: anytype,
        visitor: anytype,
    ) @TypeOf(deserializer).Error!@TypeOf(visitor).Value {
        unreachable;
    }
}.f);

const VisitorFn = fn (type) type;

/// This test function does not support:
///
/// - Recursive, user-defined containers (e.g., std.ArrayList(std.ArrayList(u8))).
/// - Raw, untagged unions.
pub fn run(comptime deserializeFn: DeserializeFn, comptime visitorFn: VisitorFn, input: []const Token, expected: anytype) !void {
    const T = @TypeOf(expected);

    var d = DefaultDeserializer.init(input);
    const deserializer = d.deserializer();

    var v = visitorFn(T){};
    const visitor = v.visitor();

    var got = deserializeFn(test_allocator, T, deserializer, visitor) catch return error.UnexpectedTestError;
    defer getty.de.free(test_allocator, got);

    switch (@typeInfo(T)) {
        .Bool,
        .Enum,
        .Float,
        .Int,
        .Optional,
        .Void,
        => try expectEqual(expected, got),
        .Array => |info| try expectEqualSlices(info.child, &expected, &got),
        .Pointer => |info| switch (comptime std.meta.trait.isZigString(T)) {
            true => try expectEqualStrings(expected, got),
            false => switch (info.size) {
                //.One => ,
                .Slice => try expectEqualSlices(info.child, expected, got),
                else => unreachable,
            },
        },
        .Struct => |info| {
            if (comptime std.mem.startsWith(u8, @typeName(T), "array_list")) {
                try expectEqual(expected.capacity, got.capacity);
                try expectEqualSlices(std.meta.Child(T.Slice), expected.items, got.items);
            } else if (comptime std.mem.startsWith(u8, @typeName(T), "linked_list.SinglyLinkedList")) {
                try expectEqual(expected.len(), got.len());
                var iterator = expected.first;

                while (iterator) |node| : (iterator = node.next) {
                    var got_node = got.popFirst();
                    try expect(got_node != null);
                    defer test_allocator.destroy(got_node.?);

                    try expectEqual(node.data, got_node.?.data);
                }
            } else if (comptime std.mem.startsWith(u8, @typeName(T), "linked_list.TailQueue")) {
                try expectEqual(expected.len, got.len);
                var iterator = expected.first;

                while (iterator) |node| : (iterator = node.next) {
                    var got_node = got.popFirst();
                    try expect(got_node != null);
                    defer test_allocator.destroy(got_node.?);

                    try expectEqual(node.data, got_node.?.data);
                }
            } else if (comptime std.mem.startsWith(u8, @typeName(T), "packed_int_array.PackedIntArrayEndian")) {
                try expectEqual(expected.len, got.len);

                for (&expected.bytes) |byte, i| {
                    try expectEqual(byte, got.bytes[i]);
                }
            } else if (T == std.BufMap) {
                try expectEqual(expected.count(), got.count());

                var it = expected.iterator();
                while (it.next()) |kv| {
                    try expectEqualSlices(u8, expected.get(kv.key_ptr.*).?, got.get(kv.key_ptr.*).?);
                }
            } else switch (info.is_tuple) {
                true => {
                    const length = std.meta.fields(T).len;
                    comptime var i: usize = 0;

                    inline while (i < length) : (i += 1) {
                        try expectEqual(expected[i], got[i]);
                    }
                },
                false => try expectEqual(expected, got),
            }
        },
        .Union => |info| {
            if (info.tag_type) |_| {
                try expectEqual(expected, got);
            } else {
                if (T == std.net.Address) {
                    try expect(std.net.Address.eql(expected, got));
                } else {
                    @compileError("untagged unions are not supported by this function");
                }
            }
        },
        else => unreachable,
    }

    try expect(d.remaining() == 0);
}

pub fn Deserializer(comptime user_dbt: anytype, comptime deserializer_dbt: anytype) type {
    return struct {
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

        pub usingnamespace getty.Deserializer(
            *Self,
            Error,
            user_dbt,
            deserializer_dbt,
            .{
                .deserializeAny = deserializeAny,
                .deserializeBool = deserializeAny,
                .deserializeEnum = deserializeAny,
                .deserializeFloat = deserializeAny,
                .deserializeInt = deserializeAny,
                .deserializeIgnored = deserializeIgnored,
                .deserializeMap = deserializeAny,
                .deserializeOptional = deserializeAny,
                .deserializeSeq = deserializeAny,
                .deserializeString = deserializeAny,
                .deserializeStruct = deserializeAny,
                .deserializeUnion = deserializeAny,
                .deserializeVoid = deserializeAny,
            },
        );

        const Error = getty.de.Error || error{TestExpectedEqual};

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

        fn deserializeIgnored(_: *Self, allocator: ?std.mem.Allocator, visitor: anytype) Error!@TypeOf(visitor).Value {
            return try visitor.visitVoid(allocator, De);
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
            de: *Self,
            len: ?usize,
            end: Token,

            pub usingnamespace getty.de.SeqAccess(
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
            de: *Self,
            len: ?usize,
            end: Token,

            pub usingnamespace getty.de.MapAccess(
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
            de: *Self,
            len: ?usize,
            end: Token,

            pub usingnamespace getty.de.MapAccess(
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
            de: *Self,

            pub usingnamespace getty.de.UnionAccess(
                *Union,
                Error,
                .{ .variantSeed = variantSeed },
            );

            pub usingnamespace getty.de.VariantAccess(
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
}

pub const DefaultDeserializer = Deserializer(null, null);
