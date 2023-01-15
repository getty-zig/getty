//! Deserialization framework.

const std = @import("std");
const t = @import("getty/testing");

const Deserializer = @import("interfaces/deserializer.zig").Deserializer;

const expectEqual = std.testing.expectEqual;

pub const default_dt = .{
    ////////////////////////////////////////////////////////////////////////////
    // Standard Library
    ////////////////////////////////////////////////////////////////////////////

    de.blocks.ArrayList,
    de.blocks.BufMap,
    de.blocks.HashMap,
    de.blocks.LinkedList,
    de.blocks.NetAddress,
    de.blocks.PackedIntArray,
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

/// A namespace containing deserialization-specific types and functions.
pub const de = struct {
    pub const Error = @import("error.zig").Error;

    pub const Visitor = @import("interfaces/visitor.zig").Visitor;

    pub const MapAccess = @import("interfaces/map_access.zig").MapAccess;
    pub const SeqAccess = @import("interfaces/seq_access.zig").SeqAccess;
    pub const UnionAccess = @import("interfaces/union_access.zig").UnionAccess;
    pub const VariantAccess = @import("interfaces/variant_access.zig").VariantAccess;

    pub const Seed = @import("interfaces/seed.zig").Seed;
    pub const DefaultSeed = @import("impls/seed/default.zig").DefaultSeed;
    pub const Ignored = @import("impls/seed/ignored.zig").Ignored;

    pub const blocks = struct {
        ////////////////////////////////////////////////////////////////////////
        // Standard Library
        ////////////////////////////////////////////////////////////////////////

        /// Deserialization block for `std.ArrayList` values.
        pub const ArrayList = @import("blocks/array_list.zig");

        /// Deserialization block for `std.BufMap` values.
        pub const BufMap = @import("blocks/buf_map.zig");

        /// Deserialization block for `std.HashMap` values.
        pub const HashMap = @import("blocks/hash_map.zig");

        /// Deserialization block for `std.SinglyLinkedList` values.
        pub const LinkedList = @import("blocks/linked_list.zig");

        /// Deserialization block for `std.net.Address` values.
        pub const NetAddress = @import("blocks/net_address.zig");

        /// Deserialization block for `std.PackedIntArray` values.
        pub const PackedIntArray = @import("blocks/packed_int_array.zig");

        /// Deserialization block for `std.TailQueue`.
        pub const TailQueue = @import("blocks/tail_queue.zig");

        ////////////////////////////////////////////////////////////////////////
        // User-Defined
        ////////////////////////////////////////////////////////////////////////

        pub const Ignored = @import("blocks/ignored.zig");

        ////////////////////////////////////////////////////////////////////////
        // Primitives
        ////////////////////////////////////////////////////////////////////////

        /// Deserializaton block for array values.
        pub const Array = @import("blocks/array.zig");

        /// Deserialization block for `bool` values.
        pub const Bool = @import("blocks/bool.zig");

        /// Deserialization block for `enum` values.
        pub const Enum = @import("blocks/enum.zig");

        /// Deserialization block for floating-point values.
        pub const Float = @import("blocks/float.zig");

        /// Deserialization block for integer values.
        pub const Int = @import("blocks/int.zig");

        /// Deserialization block for optional values.
        pub const Optional = @import("blocks/optional.zig");

        /// Deserialization block for pointer values.
        pub const Pointer = @import("blocks/pointer.zig");

        /// Deserialization block for slice values.
        pub const Slice = @import("blocks/slice.zig");

        /// Deserialization block for `struct` values.
        pub const Struct = @import("blocks/struct.zig");

        /// Deserialization block for tuple values.
        pub const Tuple = @import("blocks/tuple.zig");

        /// Deserialization block for `union` values.
        pub const Union = @import("blocks/union.zig");

        /// Deserialization block for `void` values.
        pub const Void = @import("blocks/void.zig");
    };

    /// Constraints that can be used to perform compile-time validation for a type.
    pub const concepts = struct {
        /// Specifies that a type is a `getty.Deserializer` interface type.
        pub const @"getty.Deserializer" = @import("concepts/deserializer.zig").@"getty.Deserializer";

        /// Specifies that a type is a `getty.de.Visitor` interface type.
        pub const @"getty.de.Visitor" = @import("concepts/visitor.zig").@"getty.de.Visitor";

        /// Specifies that a type is a `getty.de.MapAccess` interface type.
        pub const @"getty.de.MapAccess" = @import("concepts/map_access.zig").@"getty.de.MapAccess";

        /// Specifies that a type is a `getty.de.SeqAccess` interface type.
        pub const @"getty.de.SeqAccess" = @import("concepts/seq_access.zig").@"getty.de.SeqAccess";

        /// Specifies that a type is a `getty.de.UnionAccess` interface type.
        pub const @"getty.de.UnionAccess" = @import("concepts/union_access.zig").@"getty.de.UnionAccess";

        /// Specifies that a type is a `getty.de.VariantAccess` interface type.
        pub const @"getty.de.VariantAccess" = @import("concepts/variant_access.zig").@"getty.de.VariantAccess";

        /// Specifies that a type is a `getty.de.Seed` interface type.
        pub const @"getty.de.Seed" = @import("concepts/seed.zig").@"getty.de.Seed";

        /// Specifies that a type is a deserialization block or tuple.
        pub const @"getty.de.dbt" = @import("concepts/block.zig").@"getty.de.dbt";
    };

    /// Functions that can be used to query, at compile-time, the properties of a type.
    pub const traits = struct {
        /// Checks if a type or value is a deserialization block or tuple.
        pub const is_dbt = @import("traits/block.zig").is_dbt;

        /// Checks if a value is a deserialization attribute list.
        pub const is_attributes = @import("traits/attributes.zig").is_attributes;

        /// Checks if a type contains a deserialization block.
        pub const has_db = @import("traits/block.zig").has_db;

        /// Checks if a type has associated deserialization attributes.
        pub const has_attributes = @import("traits/attributes.zig").has_attributes;
    };

    /// Frees resources allocated by Getty during deserialization.
    ///
    /// `free` assumes that all pointers passed to it are heap-allocated and
    /// will therefore attempt to free them. So be sure not to pass in any
    /// pointers pointing to values on the stack.
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

    /// Returns the highest priority Deserialization Block for a type.
    pub fn find_db(
        /// The type being deserialized into.
        comptime T: type,
        /// A `getty.Deserializer` interface type.
        comptime De: type,
    ) type {
        comptime {
            concepts.@"getty.Deserializer"(De);

            // Process user DBs.
            for (De.user_dt) |db| {
                if (db.is(T)) {
                    return db;
                }
            }

            // Process type DBs.
            if (traits.has_db(T)) {
                return T.@"getty.db";
            }

            // Process deserializer DBs.
            for (De.deserializer_dt) |db| {
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

    /// Returns deserialization attributes for `T`. If none exist, `null` is returned.
    pub const getAttributes = @import("../attributes.zig").getDeAttributes;
};

/// Deserializes into a value of type `T` from a `getty.Deserializer`.
pub fn deserialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// The type of the value to deserialize into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
) blk: {
    de.concepts.@"getty.Deserializer"(@TypeOf(deserializer));
    break :blk @TypeOf(deserializer).Error!T;
} {
    const db = comptime de.find_db(T, @TypeOf(deserializer));

    if (comptime de.traits.has_attributes(T, db)) {
        switch (@typeInfo(T)) {
            .Struct => {
                var v = de.blocks.Struct.Visitor(T){};
                return try de.blocks.Struct.deserialize(allocator, T, deserializer, v.visitor());
            },
            .Union => {
                var v = de.blocks.Union.Visitor(T){};
                return try de.blocks.Union.deserialize(allocator, T, deserializer, v.visitor());
            },
            else => @compileError("unexpected type cannot be deserialized using attributes"),
        }
    }

    var v = db.Visitor(T){};
    return try db.deserialize(allocator, T, deserializer, v.visitor());
}

fn PointVisitor(comptime Value: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.Visitor(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        fn visitSeq(
            _: Self,
            allocator: ?std.mem.Allocator,
            comptime De: type,
            seq: anytype,
        ) De.Error!Value {
            var point: Value = undefined;

            inline for (std.meta.fields(Value)) |field| {
                if (try seq.nextElement(allocator, i32)) |elem| {
                    @field(point, field.name) = elem;
                } else {
                    return error.InvalidLength;
                }
            }

            if ((try seq.nextElement(allocator, de.Ignored)) != null) {
                return error.InvalidLength;
            }

            return point;
        }
    };
}

test "deserialize - success, normal" {
    const Point = struct {
        x: i32,
        y: i32,
    };

    const block = struct {
        pub fn is(comptime T: type) bool {
            return T == Point;
        }

        pub fn deserialize(a: ?std.mem.Allocator, comptime _: type, d: anytype, v: anytype) @TypeOf(d).Error!@TypeOf(v).Value {
            return try d.deserializeSeq(a, v);
        }

        pub const Visitor = PointVisitor;
    };

    const PointCustom = struct {
        x: i32,
        y: i32,

        const Self = @This();

        pub const @"getty.db" = struct {
            pub fn deserialize(a: ?std.mem.Allocator, comptime _: type, d: anytype, v: anytype) @TypeOf(d).Error!@TypeOf(v).Value {
                return try d.deserializeSeq(a, v);
            }

            pub const Visitor = PointVisitor;
        };
    };

    const expected = Point{ .x = 1, .y = 2 };
    const expected_custom = PointCustom{ .x = 1, .y = 2 };

    // Default DB
    {
        var d = t.de.DefaultDeserializer.init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 2 } },
            .{ .String = "x" },
            .{ .I32 = 1 },
            .{ .String = "y" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // User DB
    {
        var d = t.de.Deserializer(block, null).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // Deserializer DB
    {
        var d = t.de.Deserializer(null, block).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // Type DB
    {
        var d = t.de.DefaultDeserializer.init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        const got = deserialize(null, PointCustom, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected_custom, got);
    }
}

test "deserialize - success, attributes" {
    const attrs = .{
        .x = .{ .rename = "FOO" },
        .y = .{ .rename = "BAR" },
    };

    const Point = struct {
        x: i32,
        y: i32,
    };
    const PointCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.db" = struct {
            pub const attributes = attrs;
        };
    };

    const block = struct {
        pub fn is(comptime T: type) bool {
            return T == Point;
        }

        pub const attributes = attrs;
    };

    const expected = Point{ .x = 1, .y = 2 };
    const expected_custom = PointCustom{ .x = 1, .y = 2 };

    // User DB
    {
        var d = t.de.Deserializer(block, null).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // Deserializer DB
    {
        var d = t.de.Deserializer(null, block).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // Type DB
    {
        var d = t.de.DefaultDeserializer.init(&.{
            .{ .Struct = .{ .name = @typeName(PointCustom), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, PointCustom, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected_custom, got);
    }
}

test "deserialize - priority" {
    const attrs = .{
        .x = .{ .rename = "FOO" },
        .y = .{ .rename = "BAR" },
    };
    const invalid_attrs = .{
        .foo = .{ .bar = "TESTING" },
    };

    const Point = struct {
        x: i32,
        y: i32,
    };
    const PointCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.db" = struct {
            pub const attributes = attrs;
        };
    };
    const PointInvalidCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.db" = struct {
            pub const attributes = invalid_attrs;
        };
    };

    // Deserializer DB > Default DB
    {
        const expected = Point{ .x = 1, .y = 2 };

        const deserializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == Point;
            }

            pub const attributes = attrs;
        };

        var d = t.de.Deserializer(null, deserializer_block).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, Point, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // Type DB > Deserializer DB
    {
        const expected = PointCustom{ .x = 1, .y = 2 };

        const deserializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointCustom;
            }

            pub const attributes = invalid_attrs;
        };

        var d = t.de.Deserializer(null, deserializer_block).init(&.{
            .{ .Struct = .{ .name = @typeName(PointCustom), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, PointCustom, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }

    // User DB > Type DB
    {
        const expected = PointInvalidCustom{ .x = 1, .y = 2 };

        const user_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointInvalidCustom;
            }

            pub const attributes = attrs;
        };

        var d = t.de.Deserializer(user_block, null).init(&.{
            .{ .Struct = .{ .name = @typeName(PointInvalidCustom), .len = 2 } },
            .{ .String = "FOO" },
            .{ .I32 = 1 },
            .{ .String = "BAR" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        const got = deserialize(null, PointInvalidCustom, d.deserializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, got);
    }
}

test "getAttributes - fail" {
    const De = t.de.DefaultDeserializer.@"getty.Deserializer";

    const expected: ?void = null;

    try expectEqual(expected, de.getAttributes(bool, De));
    try expectEqual(expected, de.getAttributes(i32, De));
    try expectEqual(expected, de.getAttributes([5]i32, De));
    try expectEqual(expected, de.getAttributes(struct {}, De));
    try expectEqual(expected, de.getAttributes(union(enum) { foo, bar }, De));
    try expectEqual(expected, de.getAttributes(std.meta.Tuple(&.{ struct {}, union(enum) { foo, bar } }), De));
    try expectEqual(expected, de.getAttributes(struct {
        pub fn is(comptime _: bool) type {
            return true;
        }

        pub const attributes = .{}; // empty attribute list
    }, De));

    inline for (comptime std.meta.declarations(de.blocks)) |decl| {
        const block = @field(de.blocks, decl.name);
        try expectEqual(expected, de.getAttributes(block, De));
    }
}

test "getAttributes - success" {
    const attrs = .{
        .x = .{ .rename = "X" },
        .y = .{ .skip = true },
    };
    const expected: ?@TypeOf(attrs) = attrs;

    const Point = struct {
        x: i32,
        y: i32,
    };
    const block = struct {
        pub fn is(comptime T: type) bool {
            return T == Point;
        }

        pub const attributes = attrs;
    };

    // User DB
    {
        const D = t.de.Deserializer(block, null);
        const De = D.@"getty.Deserializer";

        try expectEqual(expected, de.getAttributes(Point, De));
    }

    // Deserializer DB
    {
        const D = t.de.Deserializer(null, block);
        const De = D.@"getty.Deserializer";

        try expectEqual(expected, de.getAttributes(Point, De));
    }

    // Type DB
    {
        const De = t.de.DefaultDeserializer.@"getty.Deserializer";

        const PointCustom = struct {
            x: i32,
            y: i32,

            pub const @"getty.db" = struct {
                pub const attributes = attrs;
            };
        };

        try expectEqual(expected, de.getAttributes(PointCustom, De));
    }
}

test "getAttributes - priority" {
    const attrs = .{
        .x = .{ .rename = "X" },
        .y = .{ .skip = true },
    };
    const invalid_attrs = .{
        .foo = .{ .bar = "TESTING" },
    };

    const Point = struct {
        x: i32,
        y: i32,
    };
    const PointCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.db" = struct {
            pub const attributes = attrs;
        };
    };
    const PointInvalidCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.db" = struct {
            pub const attributes = invalid_attrs;
        };
    };

    const expected: ?@TypeOf(attrs) = attrs;

    // User DB > Type DB
    {
        const user_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointInvalidCustom;
            }

            pub const attributes = attrs;
        };

        const D = t.de.Deserializer(user_block, null);
        const De = D.@"getty.Deserializer";

        try expectEqual(expected, de.getAttributes(PointInvalidCustom, De));
    }

    // User DB > Deserializer DB
    {
        const user_block = struct {
            pub fn is(comptime T: type) bool {
                return T == Point;
            }

            pub const attributes = attrs;
        };
        const serializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == Point;
            }

            pub const attributes = invalid_attrs;
        };

        const D = t.de.Deserializer(user_block, serializer_block);
        const De = D.@"getty.Deserializer";

        try expectEqual(expected, de.getAttributes(Point, De));
    }

    // Type DB > Deserializer DB
    {
        const serializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointCustom;
            }

            pub const attributes = invalid_attrs;
        };

        const D = t.de.Deserializer(null, serializer_block);
        const De = D.@"getty.Deserializer";

        try expectEqual(expected, de.getAttributes(PointCustom, De));
    }
}

comptime {
    std.testing.refAllDecls(@This());
}
