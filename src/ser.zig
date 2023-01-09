//! Serialization framework.

const std = @import("std");

const Serializer = @import("ser/interfaces/serializer.zig").Serializer;

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

        /// Serialization block for `std.net.Address` values.
        pub const NetAddress = @import("ser/blocks/net_address.zig");

        /// Serialization block for `std.PackedIntArray` and `std.PackedIntSlice` values.
        pub const PackedInt = @import("ser/blocks/packed_int.zig");

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
            .Union => return try ser.blocks.Union.serialize(value, serializer),
            else => @compileError("unexpected type cannot be serialized using attributes"),
        }
    }

    return try block.serialize(value, serializer);
}

comptime {
    std.testing.refAllDecls(@This());
}
