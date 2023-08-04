const blocks = @import("blocks.zig");

/// The default serialization tuple.
pub const st = .{
    ////////////////////////////////////////////////////////////////////////////
    // Primitives
    ////////////////////////////////////////////////////////////////////////////

    blocks.Array,
    blocks.Bool,
    blocks.Enum,
    blocks.Error,
    blocks.Float,
    blocks.Int,
    blocks.Null,
    blocks.Optional,
    blocks.Pointer,
    blocks.Slice,
    blocks.String,
    blocks.Tuple,
    blocks.Vector,
    blocks.Void,

    ////////////////////////////////////////////////////////////////////////////
    // Standard Library
    ////////////////////////////////////////////////////////////////////////////

    blocks.Allocator,

    // Covers the following types:
    //
    //   - std.ArrayBitSet
    //   - std.IntegerBitSet
    //   - std.StaticBitSet
    blocks.ArrayBitSet,
    blocks.IntegerBitSet,

    // Covers the following types:
    //
    //   - std.ArrayList
    //   - std.ArrayListUnmanaged
    //   - std.ArrayListAligned
    //   - std.ArrayListAlignedUnmanaged
    blocks.ArrayList,

    blocks.BoundedArray,
    blocks.BufMap,
    blocks.BufSet,
    blocks.DynamicBitSet,
    blocks.DynamicBitSetUnmanaged,

    // Covers the following types:
    //
    //   - std.EnumArray
    //   - std.IndexedArray
    blocks.IndexedArray,

    // Covers the following types:
    //
    //   - std.EnumSet
    //   - std.IndexedSet
    blocks.IndexedSet,

    // Covers the following types:
    //
    //   - std.EnumMap
    //   - std.IndexedMap
    blocks.IndexedMap,

    // Covers the following types:
    //
    //   - std.EnumMultiset
    //   - std.BoundedEnumMultiset
    blocks.BoundedEnumMultiset,

    // Covers the following types:
    //
    //   - std.HashMap
    //   - std.HashMapUnmanaged
    //   - std.AutoHashMap
    //   - std.AutoHashMapUnmanaged
    //   - std.StringHashMap
    //   - std.StringHashMapUnmanaged
    //   - std.ArrayHashMap
    //   - std.ArrayHashMapUnmanaged
    //   - std.AutoArrayHashMap
    //   - std.AutoArrayHashMapUnmanaged
    //   - std.StringArrayHashMap
    //   - std.StringArrayHashMapUnmanaged
    blocks.HashMap,

    blocks.MultiArrayList,
    blocks.NetAddress,
    blocks.Uri,

    // Covers the following types:
    //
    //   - std.PackedIntArray
    //   - std.PackedIntArrayEndian
    //   - std.PackedIntSlice
    //   - std.PackedIntSliceEndian
    blocks.PackedIntArray,

    blocks.PriorityQueue,
    blocks.PriorityDequeue,
    blocks.SinglyLinkedList,
    blocks.SemanticVersion,
    blocks.TailQueue,
    blocks.LinearFifo,
    blocks.SegmentedList,

    ////////////////////////////////////////////////////////////////////////////
    // Aggregates
    //
    // IMPORTANT: All user-defined types must be listed BEFORE this section.
    //            Each type in this section has user-defined aliases that are
    //            supported by Getty (e.g., std.ArrayList is a struct).
    ////////////////////////////////////////////////////////////////////////////

    blocks.Struct,
    blocks.Union,
};
