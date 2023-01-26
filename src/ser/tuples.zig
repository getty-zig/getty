const blocks = @import("blocks.zig");

pub const default = .{
    ////////////////////////////////////////////////////////////////////////////
    // Standard Library
    ////////////////////////////////////////////////////////////////////////////

    blocks.Allocator,
    blocks.ArrayList,
    blocks.BoundedArray,
    blocks.BufMap,
    blocks.HashMap,
    blocks.LinkedList,
    blocks.NetAddress,
    blocks.PackedInt,
    blocks.TailQueue,

    ////////////////////////////////////////////////////////////////////////////
    // Struct
    //
    // IMPORTANT: All user-defined types must be listed BEFORE this section.
    ////////////////////////////////////////////////////////////////////////////

    blocks.Struct,

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
    blocks.Union,
    blocks.Vector,
    blocks.Void,
};
