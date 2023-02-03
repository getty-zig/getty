const blocks = @import("blocks.zig");

pub const default = .{
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
    //   - std.ArrayList
    //   - std.ArrayListUnmanaged
    //   - std.ArrayListAligned
    //   - std.ArrayListAlignedUnmanaged
    blocks.ArrayList,

    blocks.BoundedArray,
    blocks.BufMap,

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

    blocks.SinglyLinkedList,
    blocks.MultiArrayList,
    blocks.NetAddress,

    // Covers the following types:
    //
    //   - std.PackedIntArray
    //   - std.PackedIntArrayEndian
    //   - std.PackedIntSlice
    //   - std.PackedIntSliceEndian
    blocks.PackedIntArray,

    blocks.SemanticVersion,
    blocks.TailQueue,

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
