const std = @import("std");

const DeserializerInterface = @import("../interfaces/deserializer.zig").Deserializer;
const getAttributes = @import("../attributes.zig").getAttributes;
const getty_deserialize = @import("../deserialize.zig").deserialize;
const getty_error = @import("../error.zig").Error;
const getty_free = @import("../free.zig").free;
const MapAccessInterface = @import("../interfaces/map_access.zig").MapAccess;
const SeqAccessInterface = @import("../interfaces/seq_access.zig").SeqAccess;
const Tag = @import("../../attributes.zig").Tag;
const testing = @import("../testing.zig");
const UnionAccessInterface = @import("../interfaces/union_access.zig").UnionAccess;
const UnionVisitor = @import("../impls/visitor/union.zig").Visitor;
const VariantAccessInterface = @import("../interfaces/variant_access.zig").VariantAccess;
const VisitorInterface = @import("../interfaces/visitor.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Union;
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) @TypeOf(deserializer).Error!@TypeOf(visitor).Value {
    const tag: Tag = comptime blk: {
        const attributes = getAttributes(T, @TypeOf(deserializer));

        if (attributes) |attrs| {
            if (@hasField(@TypeOf(attrs), "Container")) {
                if (@hasField(@TypeOf(attrs.Container), "tag")) {
                    break :blk attrs.Container.tag;
                }
            }
        }

        break :blk .external;
    };

    return switch (tag) {
        .external => try deserializeExternallyTaggedUnion(ally, deserializer, visitor),
        .untagged => try deserializeUntaggedUnion(ally, T, deserializer, visitor),
        .internal => @compileError("TODO: internally tagged representation"),
    };
}

fn deserializeExternallyTaggedUnion(
    ally: ?std.mem.Allocator,
    deserializer: anytype,
    visitor: anytype,
) @TypeOf(deserializer).Error!@TypeOf(visitor).Value {
    return try deserializer.deserializeUnion(ally, visitor);
}

// Untagged unions are only supported in self-describing formats.
fn deserializeUntaggedUnion(
    ally: ?std.mem.Allocator,
    comptime T: type,
    deserializer: anytype,
    visitor: anytype,
) @TypeOf(deserializer).Error!@TypeOf(visitor).Value {
    // Deserialize the input data into a Content value.
    //
    // This intermediate value allows us to repeatedly attempt deserialization
    // for each variant of the untagged union, without further modifying the
    // actual input data of the deserializer.
    var content = try getty_deserialize(ally, Content, deserializer);
    defer switch (content) {
        .Int, .Map, .Seq, .String, .Some => {
            // If content was successfully deserialized, and we're here, then
            // that means allocator must've not been null.
            std.debug.assert(ally != null);
            getty_free(ally.?, @TypeOf(deserializer), content);
        },
        else => {},
    };

    // Deserialize the Content value into a value of type T.
    var cd = ContentDeserializer{ .content = content };
    const d = cd.deserializer();

    inline for (std.meta.fields(T)) |field| {
        if (getty_deserialize(ally, field.type, d)) |value| {
            return @unionInit(T, field.name, value);
        } else |err| switch (err) {
            error.DuplicateField,
            error.InvalidLength,
            error.InvalidType,
            error.MissingField,
            error.MissingVariant,
            error.UnknownField,
            error.UnknownVariant,
            => {},
            else => return err,
        }
    }

    return error.MissingVariant;
}

const ContentMap = struct {
    key: Content,
    value: Content,
};

const ContentDeserializerMap = struct {
    key: ContentDeserializer,
    value: ContentDeserializer,
};

const ContentMultiArrayList = std.MultiArrayList(ContentMap);
const ContentDeserializerMultiArrayList = std.MultiArrayList(ContentDeserializerMap);

// Does not support compile-time known types.
const Content = union(enum) {
    Bool: bool,
    F16: f16,
    F32: f32,
    F64: f64,
    F128: f128,
    Int: std.math.big.int.Managed,
    Map: ContentMultiArrayList,
    Null,
    Seq: std.ArrayList(Content),
    Some: *Content,
    String: []const u8,
    Void,

    pub fn deinit(self: Content, ally: std.mem.Allocator) void {
        switch (self) {
            .Int => |v| {
                var mut = v;
                mut.deinit();
            },
            .Seq => |v| {
                for (v.items) |elem| elem.deinit(ally);
                v.deinit();
            },
            .Map => |v| {
                for (v.items(.key), v.items(.value)) |key, value| {
                    key.deinit(ally);
                    value.deinit(ally);
                }
                var mut = v;
                mut.deinit(ally);
            },
            .String => |v| ally.free(v),
            .Some => |v| {
                v.deinit(ally);
                ally.destroy(v);
            },
            else => {},
        }
    }

    pub const @"getty.db" = struct {
        pub fn deserialize(
            ally: ?std.mem.Allocator,
            comptime _: type,
            deserializer: anytype,
            visitor: anytype,
        ) !@TypeOf(visitor).Value {
            return try deserializer.deserializeAny(ally, visitor);
        }

        pub fn Visitor(comptime _: type) type {
            return struct {
                pub usingnamespace VisitorInterface(
                    @This(),
                    Content,
                    .{
                        .visitBool = visitBool,
                        .visitFloat = visitFloat,
                        .visitInt = visitInt,
                        .visitMap = visitMap,
                        .visitNull = visitNull,
                        .visitSeq = visitSeq,
                        .visitSome = visitSome,
                        .visitString = visitString,
                        .visitUnion = visitUnion,
                        .visitVoid = visitVoid,
                    },
                );

                fn visitBool(_: @This(), _: ?std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Error!Content {
                    return .{ .Bool = input };
                }

                fn visitFloat(_: @This(), _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Content {
                    return switch (@TypeOf(input)) {
                        f16 => .{ .F16 = input },
                        f32 => .{ .F32 = input },
                        f64 => .{ .F64 = input },
                        f128 => .{ .F128 = input },
                        comptime_float => @compileError("comptime_float is not supported"),
                        else => unreachable, // UNREACHABLE: The Visitor interface guarantees that input is a float.
                    };
                }

                fn visitInt(_: @This(), ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Content {
                    if (ally == null) {
                        return error.MissingAllocator;
                    }

                    return switch (@typeInfo(@TypeOf(input))) {
                        .Int => .{ .Int = try std.math.big.int.Managed.initSet(ally.?, input) },
                        .ComptimeInt => @compileError("comptime_int is not supported"),
                        else => unreachable, // UNREACHABLE: The Visitor interface guarantees that input is an integer.
                    };
                }

                fn visitMap(_: @This(), ally: ?std.mem.Allocator, comptime Deserializer: type, mapAccess: anytype) Deserializer.Error!Content {
                    if (ally == null) {
                        return error.MissingAllocator;
                    }

                    var map = ContentMultiArrayList{};
                    errdefer map.deinit(ally.?);

                    while (try mapAccess.nextKey(ally.?, Content)) |key| {
                        errdefer if (mapAccess.isKeyAllocated(@TypeOf(key))) {
                            getty_free(ally.?, Deserializer, key);
                        };

                        const value = try mapAccess.nextValue(ally, Content);
                        errdefer getty_free(ally.?, Deserializer, value);

                        try map.append(ally.?, .{
                            .key = key,
                            .value = value,
                        });
                    }

                    return .{ .Map = map };
                }

                fn visitNull(_: @This(), _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Content {
                    return .{ .Null = {} };
                }

                fn visitSeq(_: @This(), ally: ?std.mem.Allocator, comptime Deserializer: type, seqAccess: anytype) Deserializer.Error!Content {
                    if (ally == null) {
                        return error.MissingAllocator;
                    }

                    var list = std.ArrayList(Content).init(ally.?);
                    errdefer list.deinit();

                    while (try seqAccess.nextElement(ally.?, Content)) |elem| {
                        try list.append(elem);
                    }

                    return .{ .Seq = list };
                }

                fn visitSome(_: @This(), ally: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Content {
                    return .{ .Some = try getty_deserialize(ally, *Content, deserializer) };
                }

                fn visitString(_: @This(), ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Content {
                    const output = try ally.?.alloc(u8, input.len);
                    std.mem.copy(u8, output, input);

                    return .{ .String = output };
                }

                fn visitUnion(_: @This(), ally: ?std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Error!Content {
                    if (ally == null) {
                        return error.MissingAllocator;
                    }

                    var variant = try ua.variant(ally, Content);
                    errdefer if (ua.isVariantAllocated(@TypeOf(variant))) {
                        getty_free(ally.?, Deserializer, variant);
                    };

                    var payload = try va.payload(ally.?, Content);
                    errdefer getty_free(ally.?, Deserializer, payload);

                    var map = ContentMultiArrayList{};
                    errdefer map.deinit(ally.?);

                    try map.append(ally.?, .{
                        .key = variant,
                        .value = payload,
                    });

                    return .{ .Map = map };
                }

                fn visitVoid(_: @This(), _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Content {
                    return .{ .Void = {} };
                }
            };
        }

        pub fn free(ally: std.mem.Allocator, comptime _: type, value: anytype) void {
            switch (value) {
                .Int, .Map, .Seq, .String, .Some => value.deinit(ally),
                else => {},
            }
        }
    };
};

const ContentDeserializer = struct {
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

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return UnionVisitor(T);
}

/// Frees resources allocated by Getty during deserialization.
pub fn free(
    /// A memory allocator.
    ally: std.mem.Allocator,
    /// A `getty.Deserializer` interface type.
    comptime Deserializer: type,
    /// A value to deallocate.
    value: anytype,
) void {
    const info = @typeInfo(@TypeOf(value)).Union;

    if (info.tag_type) |T| {
        inline for (info.fields) |field| {
            if (value == @field(T, field.name)) {
                getty_free(ally, Deserializer, @field(value, field.name));
                break;
            }
        }
    }
}

test "deserialize - union" {
    const Tagged = union(enum) {
        foo: void,
        bar: bool,
    };

    const Untagged = union {
        foo: void,
        bar: bool,
    };

    const tests = .{
        .{
            .name = "tagged, void variant",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = true,
            .want = Tagged{ .foo = {} },
        },
        .{
            .name = "tagged, non-void variant",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = true,
            .want = Tagged{ .bar = true },
        },
        .{
            .name = "untagged, void variant",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = false,
            .tag = "foo",
            .want = {},
        },
        .{
            .name = "untagged, non-void variant",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = false,
            .tag = "bar",
            .want = true,
        },
    };

    inline for (tests) |t| {
        try runTest(t, if (t.tagged) Tagged else Untagged);
    }
}

test "deserialize - union, attributes (rename)" {
    const Tagged = union(enum) {
        foo: void,
        bar: bool,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .foo = .{ .rename = "FOO" },
                .bar = .{ .rename = "BAR" },
            };
        };
    };

    const Untagged = union {
        foo: void,
        bar: bool,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .foo = .{ .rename = "FOO" },
                .bar = .{ .rename = "BAR" },
            };
        };
    };

    const tests = .{
        .{
            .name = "tagged, void variant (success)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "FOO" },
                .{ .Void = {} },
            },
            .tagged = true,
            .want = Tagged{ .foo = {} },
        },
        .{
            .name = "tagged, void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = true,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "tagged, non-void variant (success)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "BAR" },
                .{ .Bool = true },
            },
            .tagged = true,
            .want = Tagged{ .bar = true },
        },
        .{
            .name = "tagged, non-void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = true,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "untagged, void variant (success)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "FOO" },
                .{ .Void = {} },
            },
            .tagged = false,
            .tag = "foo",
            .want = {},
        },
        .{
            .name = "untagged, void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = false,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "untagged, non-void variant (success)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "BAR" },
                .{ .Bool = true },
            },
            .tagged = false,
            .tag = "bar",
            .want = true,
        },
        .{
            .name = "untagged, non-void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = false,
            .want_err = error.UnknownVariant,
        },
    };

    inline for (tests) |t| {
        try runTest(t, if (t.tagged) Tagged else Untagged);
    }
}

test "deserialize - union, attributes (skip)" {
    const Tagged = union(enum) {
        foo: void,
        bar: bool,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .foo = .{ .skip = true },
                .bar = .{ .skip = true },
            };
        };
    };

    const Untagged = union {
        foo: void,
        bar: bool,

        pub const @"getty.db" = struct {
            pub const attributes = .{
                .foo = .{ .skip = true },
                .bar = .{ .skip = true },
            };
        };
    };

    const tests = .{
        .{
            .name = "tagged, void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = true,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "tagged, non-void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = true,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "untagged, void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "foo" },
                .{ .Void = {} },
            },
            .tagged = false,
            .want_err = error.UnknownVariant,
        },
        .{
            .name = "untagged, non-void variant (fail)",
            .tokens = &.{
                .{ .Union = {} },
                .{ .String = "bar" },
                .{ .Bool = true },
            },
            .tagged = false,
            .want_err = error.UnknownVariant,
        },
    };

    inline for (tests) |t| {
        try runTest(t, if (t.tagged) Tagged else Untagged);
    }
}

test "deserialize - union, attributes (tag, untagged)" {
    const WantTagged = union(enum) {
        Bool: bool,
        F32: f32,
        I32: i32,
        Optional: ?void,
        Map: struct { A: i32, B: i32, C: i32 },
        Seq: [3]i32,
        String: []const u8,
        Union: union(enum) { foo: i32 },
        // NOTE: The variant in this union needs to be different than all the
        // other variants in WantTagged. Otherwise, an earlier variant will be
        // deserialized into.
        UnionUntagged: union(enum) {
            Bools: [2]bool,

            pub const @"getty.db" = struct {
                pub const attributes = .{ .Container = .{ .tag = .untagged } };
            };
        },
        Void,

        pub const @"getty.db" = struct {
            pub const attributes = .{ .Container = .{ .tag = .untagged } };
        };
    };

    const tests = .{
        .{
            .name = "tagged, bool variant",
            .tokens = &.{.{ .Bool = true }},
            .want = WantTagged{ .Bool = true },
        },
        .{
            .name = "tagged, float variant",
            .tokens = &.{.{ .F32 = 3.14 }},
            .want = WantTagged{ .F32 = 3.14 },
        },
        .{
            .name = "tagged, int variant",
            .tokens = &.{.{ .I32 = 123 }},
            .want = WantTagged{ .I32 = 123 },
        },
        .{
            .name = "tagged, map variant",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .String = "A" },
                .{ .I32 = 1 },
                .{ .String = "B" },
                .{ .I32 = 2 },
                .{ .String = "C" },
                .{ .I32 = 3 },
                .{ .MapEnd = {} },
            },
            .want = WantTagged{ .Map = .{ .A = 1, .B = 2, .C = 3 } },
        },
        .{
            .name = "tagged, optional variant (null)",
            .tokens = &.{.{ .Null = {} }},
            .want = WantTagged{ .Optional = null },
        },
        .{
            .name = "tagged, optional variant (some)",
            .tokens = &.{
                .{ .Some = {} },
                .{ .Void = {} },
            },
            .want = WantTagged{ .Optional = {} },
        },
        .{
            .name = "tagged, sequence variant",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .I32 = 1 },
                .{ .I32 = 2 },
                .{ .I32 = 3 },
                .{ .SeqEnd = {} },
            },
            .want = WantTagged{ .Seq = [_]i32{ 1, 2, 3 } },
        },
        .{
            .name = "tagged, string variant",
            .tokens = &.{.{ .String = "abcdef" }},
            .want = WantTagged{ .String = "abcdef" },
        },
        .{
            .name = "tagged, union variant",
            .tokens = &.{
                .{ .Map = .{ .len = 1 } },
                .{ .String = "foo" },
                .{ .I32 = 1 },
                .{ .MapEnd = {} },
            },
            .want = WantTagged{ .Union = .{ .foo = 1 } },
        },
        .{
            .name = "tagged, union variant (untagged)",
            .tokens = &.{
                .{ .Seq = .{ .len = 2 } },
                .{ .Bool = true },
                .{ .Bool = false },
                .{ .SeqEnd = {} },
            },
            .want = WantTagged{ .UnionUntagged = .{ .Bools = [_]bool{ true, false } } },
        },
        .{
            .name = "tagged, void variant",
            .tokens = &.{.{ .Void = {} }},
            .want = WantTagged{ .Void = {} },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const Test = @TypeOf(t);

        if (@hasField(Test, "want_err")) {
            try testing.expectError(
                t.name,
                t.want_err,
                testing.deserializeErr(std.testing.allocator, @This(), Want, t.tokens),
            );
        } else {
            const got = try testing.deserialize(std.testing.allocator, t.name, @This(), Want, t.tokens);

            if (@typeInfo(@TypeOf(t.want)).Union.tag_type) |_| {
                switch (t.want) {
                    .String => |want| {
                        defer std.testing.allocator.free(got.String);
                        try testing.expectEqualSlices(t.name, u8, want, got.String);
                    },
                    else => |want| try testing.expectEqual(t.name, want, got),
                }
            } else {
                if (comptime std.mem.eql(u8, t.tag, "String")) {
                    defer std.testing.allocator.free(got.String);
                    try testing.expectEqualSlices(t.name, u8, got.want, got.String);
                } else {
                    try testing.expectEqual(t.name, t.want, @field(got, t.tag));
                }
            }
        }
    }
}

fn runTest(t: anytype, comptime Want: type) !void {
    const Test = @TypeOf(t);

    if (@hasField(Test, "want_err")) {
        try testing.expectError(
            t.name,
            t.want_err,
            testing.deserializeErr(std.testing.allocator, @This(), Want, t.tokens),
        );
    } else {
        const got = try testing.deserialize(std.testing.allocator, t.name, @This(), Want, t.tokens);

        if (t.tagged) {
            try testing.expectEqual(t.name, t.want, got);
        } else {
            try testing.expectEqual(t.name, t.want, @field(got, t.tag));
        }
    }
}
