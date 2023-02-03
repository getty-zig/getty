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
    blocks.ArrayListAligned,
    blocks.BoundedArray,
    blocks.BufMap,
    blocks.HashMap,
    blocks.LinkedList,
    blocks.MultiArrayList,
    blocks.NetAddress,
    blocks.PackedInt,
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
