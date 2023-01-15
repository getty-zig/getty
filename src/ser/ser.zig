//! Serialization framework.

const std = @import("std");
const t = @import("getty/testing");

const Serializer = @import("interfaces/serializer.zig").Serializer;

const expectEqual = std.testing.expectEqual;

pub const default_st = .{
    ////////////////////////////////////////////////////////////////////////////
    // Standard Library
    ////////////////////////////////////////////////////////////////////////////

    ser.blocks.ArrayList,
    ser.blocks.BoundedArray,
    ser.blocks.BufMap,
    ser.blocks.HashMap,
    ser.blocks.LinkedList,
    ser.blocks.NetAddress,
    ser.blocks.PackedInt,
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

/// A namespace containing serialization-specific types and functions.
pub const ser = struct {
    pub const Map = @import("interfaces/map.zig").Map;
    pub const Seq = @import("interfaces/seq.zig").Seq;
    pub const Structure = @import("interfaces/structure.zig").Structure;

    /// Serialization blocks provided by Getty.
    pub const blocks = struct {
        ////////////////////////////////////////////////////////////////////////
        // Standard Library
        ////////////////////////////////////////////////////////////////////////

        /// Serialization block for `std.ArrayList` values.
        pub const ArrayList = @import("blocks/array_list.zig");

        /// Serialization block for `std.BoundedArray` values.
        pub const BoundedArray = @import("blocks/bounded_array.zig");

        /// Serialization block for `std.BufMap` values.
        pub const BufMap = @import("blocks/buf_map.zig");

        /// Serialization block for `std.HashMap` values.
        pub const HashMap = @import("blocks/hash_map.zig");

        /// Serialization block for `std.SinglyLinkedList` values.
        pub const LinkedList = @import("blocks/linked_list.zig");

        /// Serialization block for `std.net.Address` values.
        pub const NetAddress = @import("blocks/net_address.zig");

        /// Serialization block for `std.PackedIntArray` and `std.PackedIntSlice` values.
        pub const PackedInt = @import("blocks/packed_int.zig");

        /// Serialization block for `std.TailQueue`.
        pub const TailQueue = @import("blocks/tail_queue.zig");

        ////////////////////////////////////////////////////////////////////////
        // Primitives
        ////////////////////////////////////////////////////////////////////////

        /// Serialization block for array values.
        pub const Array = @import("blocks/array.zig");

        /// Serialization block for `bool` values.
        pub const Bool = @import("blocks/bool.zig");

        /// Serialization block for `enum` values.
        pub const Enum = @import("blocks/enum.zig");

        /// Serialization block for `error` values.
        pub const Error = @import("blocks/error.zig");

        /// Serialization block for floating-point values.
        pub const Float = @import("blocks/float.zig");

        /// Serialization block for integer values.
        pub const Int = @import("blocks/int.zig");

        /// Serialization block for `null` values.
        pub const Null = @import("blocks/null.zig");

        /// Serialization block for optional values.
        pub const Optional = @import("blocks/optional.zig");

        /// Serialization block for pointer values.
        pub const Pointer = @import("blocks/pointer.zig");

        /// Serialization block for slice values.
        pub const Slice = @import("blocks/slice.zig");

        /// Serialization block for string values.
        pub const String = @import("blocks/string.zig");

        /// Serialization block for `struct` values.
        pub const Struct = @import("blocks/struct.zig");

        /// Serialization block for tuple values.
        pub const Tuple = @import("blocks/tuple.zig");

        /// Serialization block for `union` values.
        pub const Union = @import("blocks/union.zig");

        /// Serialization block for vector values.
        pub const Vector = @import("blocks/vector.zig");

        /// Serialization block for `void` values.
        pub const Void = @import("blocks/void.zig");
    };

    /// Constraints that can be used to perform compile-time validation for a type.
    pub const concepts = struct {
        /// Specifies that a type is a `getty.Serializer` interface type.
        pub const @"getty.Serializer" = @import("concepts/serializer.zig").@"getty.Serializer";

        /// Specifies that a type is a `getty.ser.Map` interface type.
        pub const @"getty.ser.Map" = @import("concepts/map.zig").@"getty.ser.Map";

        /// Specifies that a type is a `getty.ser.Seq` interface type.
        pub const @"getty.ser.Seq" = @import("concepts/seq.zig").@"getty.ser.Seq";

        /// Specifies that a type is a `getty.ser.Structure` interface type.
        pub const @"getty.ser.Structure" = @import("concepts/structure.zig").@"getty.ser.Structure";

        /// Specifies that a type is a serialization block or tuple.
        pub const @"getty.ser.sbt" = @import("concepts/block.zig").@"getty.ser.sbt";
    };

    /// Functions that can be used to query, at compile-time, the properties of a type.
    pub const traits = struct {
        /// Checks if a type or value is a serialization block or tuple.
        pub const is_sbt = @import("traits/block.zig").is_sbt;

        /// Checks if a value is a serialization attribute list.
        pub const is_attributes = @import("traits/attributes.zig").is_attributes;

        /// Checks if a type contains a serialization block.
        pub const has_sb = @import("traits/block.zig").has_sb;

        /// Checks if a type has associated serialization attributes.
        pub const has_attributes = @import("traits/attributes.zig").has_attributes;
    };

    /// Returns serialization attributes for `T`. If none exist, `null` is returned.
    pub const getAttributes = @import("../attributes.zig").getSerAttributes;
};

/// Serializes a value into a `getty.Serializer`.
pub fn serialize(
    /// A value to serialize.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) blk: {
    const S = @TypeOf(serializer);
    ser.concepts.@"getty.Serializer"(S);
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
        if (ser.traits.has_sb(T)) {
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
    if (comptime ser.traits.has_attributes(T, block)) {
        switch (@typeInfo(T)) {
            .Struct => return try ser.blocks.Struct.serialize(value, serializer),
            .Union => return try ser.blocks.Union.serialize(value, serializer),
            else => @compileError("unexpected type cannot be serialized using attributes"),
        }
    }

    return try block.serialize(value, serializer);
}

test "serialize - success, normal" {
    const Point = struct {
        x: i32,
        y: i32,
    };
    const PointCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.sb" = struct {
            pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
                var s = try serializer.serializeSeq(2);
                const seq = s.seq();

                try seq.serializeElement(value.x);
                try seq.serializeElement(value.y);

                return try seq.end();
            }
        };
    };

    const block = struct {
        pub fn is(comptime T: type) bool {
            return T == Point;
        }

        pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
            var s = try serializer.serializeSeq(2);
            const seq = s.seq();

            try seq.serializeElement(value.x);
            try seq.serializeElement(value.y);

            return try seq.end();
        }
    };

    const v = Point{ .x = 1, .y = 2 };
    const v_attrs = PointCustom{ .x = 1, .y = 2 };
    const expected: usize = 0;

    // Default SB
    {
        var s = t.ser.DefaultSerializer.init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 2 } },
            .{ .String = "x" },
            .{ .I32 = 1 },
            .{ .String = "y" },
            .{ .I32 = 2 },
            .{ .StructEnd = {} },
        });

        serialize(v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // User SB
    {
        var s = t.ser.Serializer(block, null).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        serialize(v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // Serializer SB
    {
        var s = t.ser.Serializer(null, block).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        serialize(v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // Type SB
    {
        var s = t.ser.Serializer(null, null).init(&.{
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .SeqEnd = {} },
        });

        serialize(v_attrs, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }
}

test "serialize - success, attributes" {
    const attrs = .{
        .x = .{ .rename = "TESTING" },
        .y = .{ .skip = true },
    };

    const Point = struct {
        x: i32,
        y: i32,
    };
    const PointCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.sb" = struct {
            pub const attributes = attrs;
        };
    };

    const block = struct {
        pub fn is(comptime T: type) bool {
            return T == Point;
        }

        pub const attributes = attrs;
    };

    const v = Point{ .x = 1, .y = 2 };
    const v_attrs = PointCustom{ .x = 1, .y = 2 };
    const expected: usize = 0;

    // User SB
    {
        var s = t.ser.Serializer(block, null).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // Serializer SB
    {
        var s = t.ser.Serializer(null, block).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // Type SB
    {
        var s = t.ser.Serializer(null, null).init(&.{
            .{ .Struct = .{ .name = @typeName(PointCustom), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(v_attrs, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }
}

test "serialize - priority" {
    const attrs = .{
        .x = .{ .rename = "TESTING" },
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

        pub const @"getty.sb" = struct {
            pub const attributes = attrs;
        };
    };
    const PointInvalidCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.sb" = struct {
            pub const attributes = invalid_attrs;
        };
    };

    const expected: usize = 0;

    // Serializer SB > Default SB
    {
        var v = Point{ .x = 1, .y = 2 };

        const serializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == Point;
            }

            pub const attributes = attrs;
        };

        var s = t.ser.Serializer(null, serializer_block).init(&.{
            .{ .Struct = .{ .name = @typeName(Point), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // Type SB > Serializer SB
    {
        const v = PointCustom{ .x = 1, .y = 2 };

        const serializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointCustom;
            }

            pub const attributes = invalid_attrs;
        };

        var s = t.ser.Serializer(null, serializer_block).init(&.{
            .{ .Struct = .{ .name = @typeName(PointCustom), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }

    // User SB > Type SB
    {
        const v = PointInvalidCustom{ .x = 1, .y = 2 };

        const user_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointInvalidCustom;
            }

            pub const attributes = attrs;
        };

        var s = t.ser.Serializer(user_block, null).init(&.{
            .{ .Struct = .{ .name = @typeName(PointInvalidCustom), .len = 1 } },
            .{ .String = "TESTING" },
            .{ .I32 = 1 },
            .{ .StructEnd = {} },
        });

        serialize(v, s.serializer()) catch return error.UnexpectedTestError;
        try expectEqual(expected, s.remaining());
    }
}

test "getAttributes - fail" {
    const Ser = t.ser.DefaultSerializer.@"getty.Serializer";

    const expected: ?void = null;

    try expectEqual(expected, ser.getAttributes(bool, Ser));
    try expectEqual(expected, ser.getAttributes(i32, Ser));
    try expectEqual(expected, ser.getAttributes([5]i32, Ser));
    try expectEqual(expected, ser.getAttributes(struct {}, Ser));
    try expectEqual(expected, ser.getAttributes(union(enum) { foo, bar }, Ser));
    try expectEqual(expected, ser.getAttributes(std.meta.Tuple(&.{ struct {}, union(enum) { foo, bar } }), Ser));
    try expectEqual(expected, ser.getAttributes(struct {
        pub fn is(comptime _: bool) type {
            return true;
        }

        pub const attributes = .{}; // empty attribute list
    }, Ser));

    inline for (comptime std.meta.declarations(ser.blocks)) |decl| {
        const block = @field(ser.blocks, decl.name);
        try expectEqual(expected, ser.getAttributes(block, Ser));
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

    // User SB
    {
        const S = t.ser.Serializer(block, null);
        const Ser = S.@"getty.Serializer";

        try expectEqual(expected, ser.getAttributes(Point, Ser));
    }

    // Serializer SB
    {
        const S = t.ser.Serializer(null, block);
        const Ser = S.@"getty.Serializer";

        try expectEqual(expected, ser.getAttributes(Point, Ser));
    }

    // Type SB
    {
        const Ser = t.ser.DefaultSerializer.@"getty.Serializer";

        const PointCustom = struct {
            x: i32,
            y: i32,

            pub const @"getty.sb" = struct {
                pub const attributes = attrs;
            };
        };

        try expectEqual(expected, ser.getAttributes(PointCustom, Ser));
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

        pub const @"getty.sb" = struct {
            pub const attributes = attrs;
        };
    };
    const PointInvalidCustom = struct {
        x: i32,
        y: i32,

        pub const @"getty.sb" = struct {
            pub const attributes = invalid_attrs;
        };
    };

    const expected: ?@TypeOf(attrs) = attrs;

    // User SB > Type SB
    {
        const user_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointInvalidCustom;
            }

            pub const attributes = attrs;
        };

        const S = t.ser.Serializer(user_block, null);
        const Ser = S.@"getty.Serializer";

        try expectEqual(expected, ser.getAttributes(PointInvalidCustom, Ser));
    }

    // User SB > Serializer SB
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

        const S = t.ser.Serializer(user_block, serializer_block);
        const Ser = S.@"getty.Serializer";

        try expectEqual(expected, ser.getAttributes(Point, Ser));
    }

    // Type SB > Serializer SB
    {
        const serializer_block = struct {
            pub fn is(comptime T: type) bool {
                return T == PointCustom;
            }

            pub const attributes = invalid_attrs;
        };

        const S = t.ser.Serializer(null, serializer_block);
        const Ser = S.@"getty.Serializer";

        try expectEqual(expected, ser.getAttributes(PointCustom, Ser));
    }
}

comptime {
    std.testing.refAllDecls(@This());
}
