const std = @import("std");

const Content = @import("../../content.zig").Content;
const ContentMultiArrayList = @import("../../content.zig").ContentMultiArrayList;
const DeserializerInterface = @import("../../interfaces/deserializer.zig").Deserializer;
const getty_deserialize = @import("../../deserialize.zig").deserialize;
const getty_error = @import("../../error.zig").Error;
const getty_free = @import("../../free.zig").free;
const MapAccessInterface = @import("../../interfaces/map_access.zig").MapAccess;
const SeqAccessInterface = @import("../../interfaces/seq_access.zig").SeqAccess;
const UnionAccessInterface = @import("../../interfaces/union_access.zig").UnionAccess;
const VariantAccessInterface = @import("../../interfaces/variant_access.zig").VariantAccess;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

const ContentDeserializerMap = struct {
    key: ContentDeserializer,
    value: ContentDeserializer,
};

const ContentDeserializerMultiArrayList = std.MultiArrayList(ContentDeserializerMap);

pub const ContentDeserializer = struct {
    content: Content,

    const Self = @This();

    pub usingnamespace DeserializerInterface(
        Self,
        getty_error,
        null,
        null,
        .{
            .deserializeAny = deserializeAny,
            .deserializeBool = deserializeBool,
            .deserializeEnum = deserializeEnum,
            .deserializeFloat = deserializeFloat,
            .deserializeInt = deserializeInt,
            .deserializeIgnored = deserializeIgnored,
            .deserializeMap = deserializeMap,
            .deserializeOptional = deserializeOptional,
            .deserializeSeq = deserializeSeq,
            .deserializeString = deserializeString,
            .deserializeStruct = deserializeMap,
            .deserializeUnion = deserializeUnion,
            .deserializeVoid = deserializeVoid,
        },
    );

    const De = Self.@"getty.Deserializer";

    fn deserializeAny(self: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Bool => try self.deserializeBool(ally, visitor),
            inline .F16, .F32, .F64, .F128 => try self.deserializeFloat(ally, visitor),
            .Int => blk: {
                break :blk try self.deserializeInt(ally, visitor);
            },
            .Map => |v| try visitContentMap(ally, v, visitor),
            .Null => try visitor.visitNull(ally, De),
            .Seq => |v| try visitContentSeq(ally, v, visitor),
            .Some => |v| blk: {
                var cd = Self{ .content = v.* };
                break :blk try visitor.visitSome(ally, cd.deserializer());
            },
            .String => try self.deserializeString(ally, visitor),
            .Void => try self.deserializeVoid(ally, visitor),
        };
    }

    fn deserializeBool(self: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Bool => |v| try visitor.visitBool(ally, De, v),
            else => error.InvalidType,
        };
    }

    fn deserializeEnum(self: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Int => |v| blk: {
                const int = v.to(@TypeOf(visitor).Value) catch unreachable;
                break :blk try visitor.visitInt(ally, De, int);
            },
            .String => |v| try visitor.visitString(ally, De, v),
            else => error.InvalidType,
        };
    }

    fn deserializeFloat(self: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            inline .F16, .F32, .F64, .F128 => |v| try visitor.visitFloat(ally, De, v),
            else => error.InvalidType,
        };
    }

    fn deserializeIgnored(_: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return try visitor.visitVoid(ally, De);
    }

    fn deserializeInt(self: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Int => |v| blk: {
                comptime var Value = @TypeOf(visitor).Value;

                if (@typeInfo(Value) == .Int) {
                    break :blk try visitor.visitInt(ally, De, v.to(Value) catch unreachable);
                }

                if (v.isPositive()) {
                    break :blk try visitor.visitInt(ally, De, v.to(u128) catch return error.InvalidValue);
                } else {
                    break :blk try visitor.visitInt(ally, De, v.to(i128) catch return error.InvalidValue);
                }
            },
            else => error.InvalidType,
        };
    }

    fn deserializeMap(self: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Map => |v| try visitContentMap(ally, v, visitor),
            else => error.InvalidType,
        };
    }

    fn deserializeOptional(self: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Null => try visitor.visitNull(ally, De),
            .Some => |v| blk: {
                var cd = Self{ .content = v.* };
                break :blk try visitor.visitSome(ally, cd.deserializer());
            },
            else => error.InvalidType,
        };
    }

    fn deserializeSeq(self: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Seq => |v| try visitContentSeq(ally, v, visitor),
            else => error.InvalidType,
        };
    }

    fn deserializeString(self: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .String => |v| try visitor.visitString(ally, De, v),
            else => error.InvalidType,
        };
    }

    fn deserializeUnion(self: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Map => |mal| blk: {
                const keys = mal.items(.key);
                const values = mal.items(.value);

                if (mal.len != 1 or keys.len != 1 or values.len != 1) {
                    return error.InvalidValue;
                }

                var uva = UnionVariantAccess{ .key = keys[0], .value = values[0] };
                const ua = uva.unionAccess();
                const va = uva.variantAccess();

                break :blk try visitor.visitUnion(ally, De, ua, va);
            },
            else => error.InvalidType,
        };
    }

    fn deserializeVoid(self: Self, ally: ?std.mem.Allocator, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Void => try visitor.visitVoid(ally, De),
            else => error.InvalidType,
        };
    }

    fn visitContentMap(ally: ?std.mem.Allocator, content: ContentMultiArrayList, visitor: anytype) getty_error!@TypeOf(visitor).Value {
        if (ally == null) {
            return error.MissingAllocator;
        }

        var map = ContentDeserializerMultiArrayList{};
        try map.ensureTotalCapacity(ally.?, content.len);
        defer map.deinit(ally.?);

        for (content.items(.key), content.items(.value)) |k, v| {
            map.appendAssumeCapacity(.{
                .key = ContentDeserializer{ .content = k },
                .value = ContentDeserializer{ .content = v },
            });
        }

        var ma = MapAccess{ .deserializers = map };
        return try visitor.visitMap(ally.?, De, ma.mapAccess());
    }

    fn visitContentSeq(ally: ?std.mem.Allocator, content: std.ArrayList(Content), visitor: anytype) getty_error!@TypeOf(visitor).Value {
        if (ally == null) {
            return error.MissingAllocator;
        }

        var seq = try std.ArrayList(ContentDeserializer).initCapacity(ally.?, content.items.len);
        defer seq.deinit();

        for (content.items) |c| {
            seq.appendAssumeCapacity(ContentDeserializer{ .content = c });
        }

        var sa = SeqAccess{ .deserializers = seq };
        return try visitor.visitSeq(ally.?, De, sa.seqAccess());
    }
};

const MapAccess = struct {
    pos: u64 = 0,
    deserializers: ContentDeserializerMultiArrayList,

    pub usingnamespace MapAccessInterface(
        *@This(),
        getty_error,
        .{
            .nextKeySeed = nextKeySeed,
            .nextValueSeed = nextValueSeed,
        },
    );

    fn nextKeySeed(self: *@This(), ally: ?std.mem.Allocator, seed: anytype) getty_error!?@TypeOf(seed).Value {
        if (self.pos >= self.deserializers.items(.key).len) {
            return null;
        }

        var d = self.deserializers.items(.key)[self.pos];
        return try seed.deserialize(ally, d.deserializer());
    }

    fn nextValueSeed(self: *@This(), ally: ?std.mem.Allocator, seed: anytype) getty_error!@TypeOf(seed).Value {
        var d = self.deserializers.items(.value)[self.pos];
        self.pos += 1;
        return try seed.deserialize(ally, d.deserializer());
    }
};

const SeqAccess = struct {
    pos: u64 = 0,
    deserializers: std.ArrayList(ContentDeserializer),

    pub usingnamespace SeqAccessInterface(
        *@This(),
        getty_error,
        .{ .nextElementSeed = nextElementSeed },
    );

    fn nextElementSeed(self: *@This(), ally: ?std.mem.Allocator, seed: anytype) getty_error!?@TypeOf(seed).Value {
        if (self.pos >= self.deserializers.items.len) {
            return null;
        }

        var d = self.deserializers.items[self.pos];
        self.pos += 1;

        return try seed.deserialize(ally, d.deserializer());
    }
};

const UnionVariantAccess = struct {
    key: Content,
    value: Content,

    const Self = @This();

    pub usingnamespace UnionAccessInterface(
        *Self,
        getty_error,
        .{ .variantSeed = variantSeed },
    );

    pub usingnamespace VariantAccessInterface(
        *Self,
        getty_error,
        .{ .payloadSeed = payloadSeed },
    );

    fn variantSeed(self: *Self, ally: ?std.mem.Allocator, seed: anytype) getty_error!@TypeOf(seed).Value {
        var cd = ContentDeserializer{ .content = self.key };
        return try seed.deserialize(ally, cd.deserializer());
    }

    fn payloadSeed(self: *Self, ally: ?std.mem.Allocator, seed: anytype) getty_error!@TypeOf(seed).Value {
        var cd = ContentDeserializer{ .content = self.value };
        return try seed.deserialize(ally, cd.deserializer());
    }
};
