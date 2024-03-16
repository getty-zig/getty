const blocks = @import("blocks.zig");

/// Getty's default deserialization tuple.
pub const dt = .{
    ////////////////////////////////////////////////////////////////////////////
    // Primitives
    ////////////////////////////////////////////////////////////////////////////

    blocks.Array,
    blocks.Bool,
    blocks.Enum,
    blocks.Float,
    blocks.Int,
    blocks.Optional,
    blocks.Pointer,
    blocks.Slice,
    blocks.Tuple,
    blocks.Void,

    ////////////////////////////////////////////////////////////////////////////
    // Standard Library
    ////////////////////////////////////////////////////////////////////////////

    blocks.Allocator,
    blocks.ArrayBitSet,

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
    blocks.EnumArray,
    blocks.EnumMap,
    blocks.EnumSet,

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

    blocks.IntegerBitSet,
    //blocks.MultiArrayList,
    //blocks.NetAddress,
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
    blocks.SemanticVersion,
    blocks.SinglyLinkedList,
    blocks.DoublyLinkedList,
    blocks.LinearFifo,
    blocks.SegmentedList,

    ////////////////////////////////////////////////////////////////////////////
    // User-Defined
    ////////////////////////////////////////////////////////////////////////////

    blocks.Ignored,

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
