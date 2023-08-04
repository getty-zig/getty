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

/// Serialization block for tuple values.
pub const Tuple = @import("blocks/tuple.zig");

/// Serialization block for vector values.
pub const Vector = @import("blocks/vector.zig");

/// Serialization block for `void` values.
pub const Void = @import("blocks/void.zig");

////////////////////////////////////////////////////////////////////////
// Standard Library
////////////////////////////////////////////////////////////////////////

/// Serialization block for `std.mem.Allocator` values.
pub const Allocator = @import("blocks/allocator.zig");

/// Serialization block for `std.ArrayBitSet` values.
pub const ArrayBitSet = @import("blocks/array_bit_set.zig");

/// Serialization block for `std.ArrayHashMap` values.
pub const ArrayHashMap = _HashMap;

/// Serialization block for `std.ArrayHashMapUnmanaged` values.
pub const ArrayHashMapUnmanaged = _HashMap;

/// Serialization block for `std.ArrayList` values.
pub const ArrayList = _ArrayListAligned;

/// Serialization block for `std.ArrayListUnmanaged` values.
pub const ArrayListUnmanaged = _ArrayListAligned;

/// Serialization block for `std.ArrayListAligned` values.
pub const ArrayListAligned = _ArrayListAligned;

/// Serialization block for `std.ArrayListAlignedUnmanaged` values.
pub const ArrayListAlignedUnmanaged = _ArrayListAligned;

/// Serialization block for `std.AutoArrayHashMap` values.
pub const AutoArrayHashMap = _HashMap;

/// Serialization block for `std.AutoArrayHashMapUnmanaged` values.
pub const AutoArrayHashMapUnmanaged = _HashMap;

/// Serialization block for `std.AutoHashMap` values.
pub const AutoHashMap = _HashMap;

/// Serialization block for `std.AutoHashMapUnmanaged` values.
pub const AutoHashMapUnmanaged = _HashMap;

/// Serialization block for `std.BoundedArray` values.
pub const BoundedArray = @import("blocks/bounded_array.zig");

/// Serialization block for `std.BufMap` values.
pub const BufMap = @import("blocks/buf_map.zig");

/// Serialization block for `std.BufSet` values.
pub const BufSet = @import("blocks/buf_set.zig");

/// Serialization block for `std.DynamicBitSet` values.
pub const DynamicBitSet = @import("blocks/dynamic_bit_set.zig");

/// Serialization block for `std.DynamicBitSetUnmanaged` values.
pub const DynamicBitSetUnmanaged = @import("blocks/dynamic_bit_set_unmanaged.zig");

/// Serialization block for `std.EnumArray` values.
pub const EnumArray = _IndexedArray;

/// Serialization block for `std.IndexedArray` values.
pub const IndexedArray = _IndexedArray;

/// Serialization block for `std.EnumSet` values.
pub const EnumSet = _IndexedSet;

/// Serialization block for `std.IndexedSet` values.
pub const IndexedSet = _IndexedSet;

/// Serialization block for `std.EnumMap` values.
pub const EnumMap = _IndexedMap;

/// Serialization block for `std.IndexedMap` values.
pub const IndexedMap = _IndexedMap;

/// Serialization block for `std.EnumMultiset` values.
pub const EnumMultiset = _EnumMultiset;

/// Serialization block for `std.IndexedSet` values.
pub const BoundedEnumMultiset = _EnumMultiset;

/// Serialization block for `std.HashMap` values.
pub const HashMap = _HashMap;

/// Serialization block for `std.HashMapUnmanaged` values.
pub const HashMapUnmanaged = _HashMap;

/// Serialization block for `std.IntegerBitSet` values.
pub const IntegerBitSet = @import("blocks/integer_bit_set.zig");

/// Serialization block for `std.MultiArrayList` values.
pub const MultiArrayList = @import("blocks/multi_array_list.zig");

/// Serialization block for `std.net.Address` values.
pub const NetAddress = @import("blocks/net_address.zig");

/// Serialization block for `std.Uri` values.
pub const Uri = @import("blocks/uri.zig");

/// Serialization block for `std.PackedIntArray` values.
pub const PackedIntArray = _PackedIntEndian;

/// Serialization block for `std.PackedIntSlice` values.
pub const PackedIntSlice = _PackedIntEndian;

/// Serialization block for `std.PackedIntArrayEndian` values.
pub const PackedIntArrayEndian = _PackedIntEndian;

/// Serialization block for `std.PackedIntSliceEndian` values.
pub const PackedIntSliceEndian = _PackedIntEndian;

/// Serialization block for `std.SemanticVersion`.
pub const SemanticVersion = @import("blocks/semantic_version.zig");

/// Serialization block for `std.PriorityQueue` values.
pub const PriorityQueue = @import("blocks/priority_queue.zig");

/// Serialization block for `std.PriorityDequeue` values.
pub const PriorityDequeue = @import("blocks/priority_dequeue.zig");

/// Serialization block for `std.SinglyLinkedList` values.
pub const SinglyLinkedList = @import("blocks/singly_linked_list.zig");

/// Serialization block for `std.StaticBitSet`.
pub const StaticBitSet = @import("blocks/static_bit_set.zig");

/// Serialization block for `std.StringArrayHashMap` values.
pub const StringArrayHashMap = _HashMap;

/// Serialization block for `std.StringArrayHashMapUnmanaged` values.
pub const StringArrayHashMapUnmanaged = _HashMap;

/// Serialization block for `std.StringHashMap` values.
pub const StringHashMap = _HashMap;

/// Serialization block for `std.StringHashMapUnmanaged` values.
pub const StringHashMapUnmanaged = _HashMap;

/// Serialization block for `std.TailQueue`.
pub const TailQueue = @import("blocks/tail_queue.zig");

/// Serialization block for `std.LinearFifo`.
pub const LinearFifo = @import("blocks/linear_fifo.zig");

/// Serialization block for `std.SegmentedList`.
pub const SegmentedList = @import("blocks/segmented_list.zig");

////////////////////////////////////////////////////////////////////////////
// Aggregates
//
// IMPORTANT: All user-defined types must be listed BEFORE this section.
//            Each type in this section has user-defined aliases that are
//            supported by Getty (e.g., std.ArrayList is a struct).
////////////////////////////////////////////////////////////////////////////

/// Serialization block for `struct` values.
pub const Struct = @import("blocks/struct.zig");

/// Serialization block for `union` values.
pub const Union = @import("blocks/union.zig");

////////////////////////////////////////////////////////////////////////////
// Private
////////////////////////////////////////////////////////////////////////////

const _ArrayListAligned = @import("blocks/array_list_aligned.zig");
const _HashMap = @import("blocks/hash_map.zig");
const _PackedIntEndian = @import("blocks/packed_int_endian.zig");
const _IndexedArray = @import("blocks/indexed_array.zig");
const _IndexedSet = @import("blocks/indexed_set.zig");
const _IndexedMap = @import("blocks/indexed_map.zig");
const _EnumMultiset = @import("blocks/enum_multiset.zig");
