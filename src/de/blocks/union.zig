const std = @import("std");

const Content = @import("../content.zig").Content;
const ContentDeserializer = @import("../impls/deserializer/content.zig").ContentDeserializer;
const getAttributes = @import("../attributes.zig").getAttributes;
const getty_deserialize = @import("../deserialize.zig").deserialize;
const getty_error = @import("../error.zig").Error;
const getty_free = @import("../free.zig").free;
const Tag = @import("../../attributes.zig").Tag;
const testing = @import("../testing.zig");
const UnionAccessInterface = @import("../interfaces/union_access.zig").UnionAccess;
const UnionVisitor = @import("../impls/visitor/union.zig").Visitor;
const VariantAccessInterface = @import("../interfaces/variant_access.zig").VariantAccess;

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
            errdefer if (ally) |a| {
                getty_free(a, @TypeOf(d), value);
            };

            var tuva = TransparentUnionVariantAccess(@TypeOf(field.name), @TypeOf(value)){
                .variant = field.name,
                .payload = value,
            };
            const ua = tuva.unionAccess();
            const va = tuva.variantAccess();

            return try visitor.visitUnion(ally, @TypeOf(d), ua, va);
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

fn TransparentUnionVariantAccess(comptime Variant: type, comptime Payload: type) type {
    return struct {
        variant: Variant,
        payload: Payload,

        const Self = @This();

        pub usingnamespace UnionAccessInterface(
            Self,
            getty_error,
            .{
                .variantSeed = variantSeed,
                .isVariantAllocated = isAllocated,
            },
        );

        pub usingnamespace VariantAccessInterface(
            Self,
            getty_error,
            .{
                .payloadSeed = payloadSeed,
                .isPayloadAllocated = isAllocated,
            },
        );

        fn variantSeed(self: Self, _: ?std.mem.Allocator, seed: anytype) getty_error!@TypeOf(seed).Value {
            return self.variant;
        }

        fn payloadSeed(self: Self, _: ?std.mem.Allocator, seed: anytype) getty_error!@TypeOf(seed).Value {
            // This check prevents deserializeUntaggedUnion from having
            // multiple return statements with different return types when its
            // inline loop is unrolled.
            if (@TypeOf(seed).Value != Payload) {
                return error.InvalidType;
            }

            return self.payload;
        }

        fn isAllocated(_: Self, comptime _: type) bool {
            return false;
        }
    };
}

test "deserialize - union" {
    const Tagged = union(enum) {
        foo: void,
        bar: bool,
    };

    const Bare = union {
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
        try runTest(t, if (t.tagged) Tagged else Bare);
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

    const Bare = union {
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
        try runTest(t, if (t.tagged) Tagged else Bare);
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

    const Bare = union {
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
        try runTest(t, if (t.tagged) Tagged else Bare);
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
            Ints: [2]i32,

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
            .name = "tagged, union variant (untagged, I)",
            .tokens = &.{
                .{ .Seq = .{ .len = 2 } },
                .{ .Bool = true },
                .{ .Bool = false },
                .{ .SeqEnd = {} },
            },
            .want = WantTagged{ .UnionUntagged = .{ .Bools = [_]bool{ true, false } } },
        },
        .{
            .name = "tagged, union variant (untagged, II)",
            .tokens = &.{
                .{ .Seq = .{ .len = 2 } },
                .{ .I32 = 1 },
                .{ .I32 = 2 },
                .{ .SeqEnd = {} },
            },
            .want = WantTagged{ .UnionUntagged = .{ .Ints = [_]i32{ 1, 2 } } },
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
