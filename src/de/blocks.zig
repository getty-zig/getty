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

////////////////////////////////////////////////////////////////////////
// Standard Library
////////////////////////////////////////////////////////////////////////

/// Deserialization block for `std.mem.Allocator` values.
pub const Allocator = @import("blocks/allocator.zig");

/// Deserialization block for `std.ArrayBitSet` values.
pub const ArrayBitSet = _StaticBitSet;

/// Deserialization block for `std.ArrayHashMap` values.
pub const ArrayHashMap = _HashMap;

/// Deserialization block for `std.ArrayHashMapUnmanaged` values.
pub const ArrayHashMapUnmanaged = _HashMap;

/// Deserialization block for `std.ArrayList` values.
pub const ArrayList = _ArrayListAligned;

/// Deserialization block for `std.ArrayListUnmanaged` values.
pub const ArrayListUnmanaged = _ArrayListAligned;

/// Deserialization block for `std.ArrayListAligned` values.
pub const ArrayListAligned = _ArrayListAligned;

/// Deserialization block for `std.ArrayListAlignedUnmanaged` values.
pub const ArrayListAlignedUnmanaged = _ArrayListAligned;

/// Deserialization block for `std.AutoArrayHashMap` values.
pub const AutoArrayHashMap = _HashMap;

/// Deserialization block for `std.AutoArrayHashMapUnmanaged` values.
pub const AutoArrayHashMapUnmanaged = _HashMap;

/// Deserialization block for `std.AutoHashMap` values.
pub const AutoHashMap = _HashMap;

/// Deserialization block for `std.AutoHashMapUnmanaged` values.
pub const AutoHashMapUnmanaged = _HashMap;

/// Deserialization block for `std.BoundedArray` values.
pub const BoundedArray = @import("blocks/bounded_array.zig");

/// Deserialization block for `std.BufMap` values.
pub const BufMap = @import("blocks/buf_map.zig");

/// Deserialization block for `std.BufSet` values.
pub const BufSet = @import("blocks/buf_set.zig");

/// Deserialization block for `std.DynamicBitSet` values.
pub const DynamicBitSet = _DynamicBitSet;

/// Deserialization block for `std.DynamicBitSetUnmanaged` values.
pub const DynamicBitSetUnmanaged = _DynamicBitSet;

/// Deserialization block for `std.EnumArray` values.
pub const EnumArray = _IndexedArray;

/// Deserialization block for `std.IndexedArray` values.
pub const IndexedArray = _IndexedArray;

/// Deserialization block for `std.EnumSet` values.
pub const EnumSet = _IndexedSet;

/// Deserialization block for `std.IndexedSet` values.
pub const IndexedSet = _IndexedSet;

/// Deserialization block for `std.Enummap` values.
pub const EnumMap = _IndexedMap;

/// Deserialization block for `std.IndexedMap` values.
pub const IndexedMap = _IndexedMap;

/// Deserialization block for `std.EnumMultiset` values.
pub const EnumMultiset = _EnumMultiset;

/// Deserialization block for `std.BoundedEnumMultiset` values.
pub const BoundedEnumMultiset = _EnumMultiset;

/// Deserialization block for `std.HashMap` values.
pub const HashMap = _HashMap;

/// Deserialization block for `std.IntegerBitSet` values.
pub const IntegerBitSet = _StaticBitSet;

/// Deserialization block for `std.HashMapUnmanaged` values.
pub const HashMapUnmanaged = _HashMap;

/// Deserialization block for `std.MultiArrayList` values.
pub const MultiArrayList = @import("blocks/multi_array_list.zig");

/// Deserialization block for `std.net.Address` values.
pub const NetAddress = @import("blocks/net_address.zig");

/// Deserialization block for `std.Uri`.
pub const Uri = @import("blocks/uri.zig");

/// Deserialization block for `std.PackedIntArray` values.
pub const PackedIntArray = _PackedIntEndian;

/// Deserialization block for `std.PackedIntSlice` values.
pub const PackedIntSlice = _PackedIntEndian;

/// Deserialization block for `std.PackedIntArrayEndian` values.
pub const PackedIntArrayEndian = _PackedIntEndian;

/// Deserialization block for `std.PackedIntSliceEndian` values.
pub const PackedIntSliceEndian = _PackedIntEndian;

/// Deserialization block for `std.SemanticVersion`.
pub const SemanticVersion = @import("blocks/semantic_version.zig");

/// Deserialization block for `std.PriorityQueue` values.
pub const PriorityQueue = @import("blocks/priority_queue.zig");

/// Deserialization block for `std.PriorityDequeue` values.
pub const PriorityDequeue = @import("blocks/priority_dequeue.zig");

/// Deserialization block for `std.SinglyLinkedList` values.
pub const SinglyLinkedList = @import("blocks/singly_linked_list.zig");

/// Deserialization block for `std.StaticBitSet` values.
pub const StaticBitSet = _StaticBitSet;

/// Deserialization block for `std.StringArrayHashMap` values.
pub const StringArrayHashMap = _HashMap;

/// Deserialization block for `std.StringArrayHashMapUnmanaged` values.
pub const StringArrayHashMapUnmanaged = _HashMap;

/// Deserialization block for `std.StringHashMap` values.
pub const StringHashMap = _HashMap;

/// Deserialization block for `std.StringHashMapUnmanaged` values.
pub const StringHashMapUnmanaged = _HashMap;

/// Deserialization block for `std.TailQueue`.
pub const TailQueue = @import("blocks/tail_queue.zig");

/// Deserialization block for `std.LinearFifo`.
pub const LinearFifo = @import("blocks/linear_fifo.zig");

/// Deserialization block for `std.SegmentedList`.
pub const SegmentedList = @import("blocks/segmented_list.zig");

////////////////////////////////////////////////////////////////////////
// User-Defined
////////////////////////////////////////////////////////////////////////

/// Deserialization block for `getty.de.Ignored` values.
pub const Ignored = @import("blocks/ignored.zig");

////////////////////////////////////////////////////////////////////////////
// Private
////////////////////////////////////////////////////////////////////////////

const _ArrayListAligned = @import("blocks/array_list_aligned.zig");
const _DynamicBitSet = @import("blocks/dynamic_bit_set.zig");
const _HashMap = @import("blocks/hash_map.zig");
const _PackedIntEndian = @import("blocks/packed_int_endian.zig");
const _StaticBitSet = @import("blocks/static_bit_set.zig");
const _IndexedArray = @import("blocks/indexed_array.zig");
const _IndexedSet = @import("blocks/indexed_set.zig");
const _IndexedMap = @import("blocks/indexed_map.zig");
const _EnumMultiset = @import("blocks/enum_multiset.zig");
