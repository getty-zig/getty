////////////////////////////////////////////////////////////////////////
// Standard Library
////////////////////////////////////////////////////////////////////////

/// Deserialization block for `std.mem.Allocator` values.
pub const Allocator = @import("blocks/allocator.zig");

/// Deserialization block for `std.ArrayList` values.
pub const ArrayList = @import("blocks/array_list.zig");

/// Deserialization block for `std.BoundedArray` values.
pub const BoundedArray = @import("blocks/bounded_array.zig");

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

////////////////////////////////////////////////////////////////////////////
// Struct
//
// IMPORTANT: All user-defined types must be listed BEFORE this section.
////////////////////////////////////////////////////////////////////////////

/// Deserialization block for `struct` values.
pub const Struct = @import("blocks/struct.zig");

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

/// Deserialization block for tuple values.
pub const Tuple = @import("blocks/tuple.zig");

/// Deserialization block for `union` values.
pub const Union = @import("blocks/union.zig");

/// Deserialization block for `void` values.
pub const Void = @import("blocks/void.zig");
