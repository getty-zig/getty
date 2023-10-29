const std = @import("std");

const Content = @import("../../content.zig").Content;
const ContentMultiArrayList = @import("../../content.zig").ContentMultiArrayList;
const DeserializerInterface = @import("../../interfaces/deserializer.zig").Deserializer;
const getty_deserialize = @import("../../deserialize.zig").deserialize;
const getty_error = @import("../../error.zig").Error;
const MapAccessInterface = @import("../../interfaces/map_access.zig").MapAccess;
const SeqAccessInterface = @import("../../interfaces/seq_access.zig").SeqAccess;
const StringLifetime = @import("../../lifetime.zig").StringLifetime;
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

    fn deserializeAny(
        self: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Bool => try self.deserializeBool(
                result_ally,
                scratch_ally,
                visitor,
            ),
            inline .F16, .F32, .F64, .F128 => try self.deserializeFloat(
                result_ally,
                scratch_ally,
                visitor,
            ),
            .Int => try self.deserializeInt(
                result_ally,
                scratch_ally,
                visitor,
            ),
            .Map => |v| try visitContentMap(
                result_ally,
                scratch_ally,
                v,
                visitor,
            ),
            .Null => try visitor.visitNull(
                result_ally,
                scratch_ally,
                De,
            ),
            .Seq => |v| try visitContentSeq(
                result_ally,
                scratch_ally,
                v,
                visitor,
            ),
            .Some => |v| blk: {
                var cd = Self{ .content = v.* };
                const d = cd.deserializer();

                break :blk try visitor.visitSome(
                    result_ally,
                    scratch_ally,
                    d,
                );
            },
            .String => try self.deserializeString(
                result_ally,
                scratch_ally,
                visitor,
            ),
            .Void => try self.deserializeVoid(
                result_ally,
                scratch_ally,
                visitor,
            ),
        };
    }

    fn deserializeBool(
        self: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Bool => |v| try visitor.visitBool(
                result_ally,
                scratch_ally,
                De,
                v,
            ),
            else => error.InvalidType,
        };
    }

    fn deserializeEnum(
        self: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Int => |v| blk: {
                const int = v.to(@TypeOf(visitor).Value) catch unreachable;
                break :blk try visitor.visitInt(
                    result_ally,
                    scratch_ally,
                    De,
                    int,
                );
            },
            .String => |v| blk: {
                var ret = try visitor.visitString(
                    result_ally,
                    scratch_ally,
                    De,
                    v,
                    .managed,
                );
                break :blk ret.value;
            },
            else => error.InvalidType,
        };
    }

    fn deserializeFloat(
        self: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            inline .F16, .F32, .F64, .F128 => |v| try visitor.visitFloat(
                result_ally,
                scratch_ally,
                De,
                v,
            ),
            else => error.InvalidType,
        };
    }

    fn deserializeIgnored(
        _: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return try visitor.visitVoid(result_ally, scratch_ally, De);
    }

    fn deserializeInt(
        self: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Int => |v| blk: {
                comptime var Value = @TypeOf(visitor).Value;

                if (@typeInfo(Value) == .Int) {
                    break :blk try visitor.visitInt(
                        result_ally,
                        scratch_ally,
                        De,
                        v.to(Value) catch unreachable,
                    );
                }

                if (v.isPositive()) {
                    break :blk try visitor.visitInt(
                        result_ally,
                        scratch_ally,
                        De,
                        v.to(u128) catch return error.InvalidValue,
                    );
                } else {
                    break :blk try visitor.visitInt(
                        result_ally,
                        scratch_ally,
                        De,
                        v.to(i128) catch return error.InvalidValue,
                    );
                }
            },
            else => error.InvalidType,
        };
    }

    fn deserializeMap(
        self: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Map => |v| try visitContentMap(
                result_ally,
                scratch_ally,
                v,
                visitor,
            ),
            else => error.InvalidType,
        };
    }

    fn deserializeOptional(
        self: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Null => try visitor.visitNull(
                result_ally,
                scratch_ally,
                De,
            ),
            .Some => |v| blk: {
                var cd = Self{ .content = v.* };
                const d = cd.deserializer();

                break :blk try visitor.visitSome(
                    result_ally,
                    scratch_ally,
                    d,
                );
            },
            else => error.InvalidType,
        };
    }

    fn deserializeSeq(
        self: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Seq => |v| try visitContentSeq(
                result_ally,
                scratch_ally,
                v,
                visitor,
            ),
            else => error.InvalidType,
        };
    }

    fn deserializeString(
        self: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .String => |v| blk: {
                var ret = try visitor.visitString(
                    result_ally,
                    scratch_ally,
                    De,
                    v,
                    .managed,
                );
                break :blk ret.value;
            },
            else => error.InvalidType,
        };
    }

    fn deserializeUnion(
        self: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Map => |mal| blk: {
                const keys = mal.items(.key);
                const values = mal.items(.value);

                if (mal.len != 1 or keys.len != 1 or values.len != 1) {
                    return error.InvalidValue;
                }

                var uva = UnionVariantAccess{
                    .key = keys[0],
                    .value = values[0],
                };
                const ua = uva.unionAccess();
                const va = uva.variantAccess();

                break :blk try visitor.visitUnion(
                    result_ally,
                    scratch_ally,
                    De,
                    ua,
                    va,
                );
            },
            else => error.InvalidType,
        };
    }

    fn deserializeVoid(
        self: Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        return switch (self.content) {
            .Void => try visitor.visitVoid(result_ally, scratch_ally, De),
            else => error.InvalidType,
        };
    }

    fn visitContentMap(
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        content: ContentMultiArrayList,
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        var map = ContentDeserializerMultiArrayList{};
        try map.ensureTotalCapacity(scratch_ally, content.len);
        defer map.deinit(scratch_ally);

        for (content.items(.key), content.items(.value)) |k, v| {
            map.appendAssumeCapacity(.{
                .key = ContentDeserializer{ .content = k },
                .value = ContentDeserializer{ .content = v },
            });
        }

        var ma = MapAccess{ .deserializers = map };
        return try visitor.visitMap(
            result_ally,
            scratch_ally,
            De,
            ma.mapAccess(),
        );
    }

    fn visitContentSeq(
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        content: std.ArrayList(Content),
        visitor: anytype,
    ) getty_error!@TypeOf(visitor).Value {
        var seq = try std.ArrayList(ContentDeserializer).initCapacity(
            scratch_ally,
            content.items.len,
        );
        defer seq.deinit();

        for (content.items) |c| {
            seq.appendAssumeCapacity(ContentDeserializer{ .content = c });
        }

        var sa = SeqAccess{ .deserializers = seq };
        return try visitor.visitSeq(
            result_ally,
            scratch_ally,
            De,
            sa.seqAccess(),
        );
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

    fn nextKeySeed(
        self: *@This(),
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        seed: anytype,
    ) getty_error!?@TypeOf(seed).Value {
        if (self.pos >= self.deserializers.items(.key).len) {
            return null;
        }

        var d = self.deserializers.items(.key)[self.pos];
        var result = try seed.deserialize(
            result_ally,
            scratch_ally,
            d.deserializer(),
        );
        return result.value;
    }

    fn nextValueSeed(
        self: *@This(),
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        seed: anytype,
    ) getty_error!@TypeOf(seed).Value {
        var d = self.deserializers.items(.value)[self.pos];
        self.pos += 1;

        var result = try seed.deserialize(
            result_ally,
            scratch_ally,
            d.deserializer(),
        );
        return result.value;
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

    fn nextElementSeed(
        self: *@This(),
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        seed: anytype,
    ) getty_error!?@TypeOf(seed).Value {
        if (self.pos >= self.deserializers.items.len) {
            return null;
        }

        var d = self.deserializers.items[self.pos];
        self.pos += 1;

        var result = try seed.deserialize(
            result_ally,
            scratch_ally,
            d.deserializer(),
        );
        return result.value;
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

    fn variantSeed(
        self: *Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        seed: anytype,
    ) getty_error!@TypeOf(seed).Value {
        var cd = ContentDeserializer{ .content = self.key };
        var result = try seed.deserialize(
            result_ally,
            scratch_ally,
            cd.deserializer(),
        );
        return result.value;
    }

    fn payloadSeed(
        self: *Self,
        result_ally: std.mem.Allocator,
        scratch_ally: std.mem.Allocator,
        seed: anytype,
    ) getty_error!@TypeOf(seed).Value {
        var cd = ContentDeserializer{ .content = self.value };
        var result = try seed.deserialize(
            result_ally,
            scratch_ally,
            cd.deserializer(),
        );
        return result.value;
    }
};
