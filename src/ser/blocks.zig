//! The `blocks` namespace provides definitions of commonly used _Serialization
//! Blocks_.

////////////////////////////////////////////////////////////////////////////////
// Primitives
////////////////////////////////////////////////////////////////////////////////

pub const Array = @import("blocks/array.zig");
pub const Bool = @import("blocks/bool.zig");
pub const Enum = @import("blocks/enum.zig");
pub const Error = @import("blocks/error.zig");
pub const Float = @import("blocks/float.zig");
pub const Int = @import("blocks/int.zig");
pub const Null = @import("blocks/null.zig");
pub const Optional = @import("blocks/optional.zig");
pub const Pointer = @import("blocks/pointer.zig");
pub const Slice = @import("blocks/slice.zig");
pub const String = @import("blocks/string.zig");
pub const Tuple = @import("blocks/tuple.zig");
pub const Vector = @import("blocks/vector.zig");
pub const Void = @import("blocks/void.zig");

////////////////////////////////////////////////////////////////////////////////
// Standard Library
////////////////////////////////////////////////////////////////////////////////

pub const Allocator = @import("blocks/allocator.zig");
pub const ArrayBitSet = @import("blocks/array_bit_set.zig");

/// `ArrayHashMap` is a _Serialization Block_ for `std.ArrayHashMap` values.
pub const ArrayHashMap = _HashMap;

/// `ArrayHashMapUnmanaged` is a _Serialization Block_ for `std.ArrayHashMapUnmanaged` values.
pub const ArrayHashMapUnmanaged = _HashMap;

/// `ArrayList` is a _Serialization Block_ for `std.ArrayList` values.
pub const ArrayList = _ArrayListAligned;

/// `ArrayListAligned` is a _Serialization Block_ for `std.ArrayListAligned` values.
pub const ArrayListAligned = _ArrayListAligned;

/// `ArrayListAlignedUnmanaged` is a _Serialization Block_ for `std.ArrayListAlignedUnmanaged` values.
pub const ArrayListAlignedUnmanaged = _ArrayListAligned;

/// `ArrayListUnmanaged` is a _Serialization Block_ for `std.ArrayListUnmanaged` values.
pub const ArrayListUnmanaged = _ArrayListAligned;

/// `AutoArrayHashMap` is a _Serialization Block_ for `std.AutoArrayHashMap` values.
pub const AutoArrayHashMap = _HashMap;

/// `AutoArrayHashMapUnmanaged` is a _Serialization Block_ for `std.AutoArrayHashMapUnmanaged` values.
pub const AutoArrayHashMapUnmanaged = _HashMap;

/// `AutoHashMap` is a _Serialization Block_ for `std.AutoHashMap` values.
pub const AutoHashMap = _HashMap;

/// `AutoHashMapUnmanaged` is a _Serialization Block_ for `std.AutoHashMapUnmanaged` values.
pub const AutoHashMapUnmanaged = _HashMap;

pub const BoundedArray = @import("blocks/bounded_array.zig");

/// `BoundedEnumMultiset` is a _Serialization Block_ for `std.BoundedEnumMultiset` values.
pub const BoundedEnumMultiset = _EnumMultiset;

pub const BufMap = @import("blocks/buf_map.zig");
pub const BufSet = @import("blocks/buf_set.zig");
pub const DoublyLinkedList = @import("blocks/doubly_linked_list.zig");
pub const DynamicBitSet = @import("blocks/dynamic_bit_set.zig");
pub const DynamicBitSetUnmanaged = @import("blocks/dynamic_bit_set_unmanaged.zig");

/// `EnumArray` is a _Serialization Block_ for `std.EnumArray` values.
pub const EnumArray = @import("blocks/enum_array.zig");

/// `EnumMap` is a _Serialization Block_ for `std.EnumMap` values.
pub const EnumMap = _IndexedMap;

/// `EnumMultiset` is a _Serialization Block_ for `std.EnumMultiset` values.
pub const EnumMultiset = _EnumMultiset;

/// `EnumSet` is a _Serialization Block_ for `std.EnumSet` values.
pub const EnumSet = @import("blocks/enum_set.zig");

/// `HashMap` is a _Serialization Block_ for `std.HashMap` values.
pub const HashMap = _HashMap;

/// `HashMapUnmanaged` is a _Serialization Block_ for `std.HashMapUnmanaged` values.
pub const HashMapUnmanaged = _HashMap;

/// `IndexedMap` is a _Serialization Block_ for `std.IndexedMap` values.
pub const IndexedMap = _IndexedMap;

pub const IntegerBitSet = @import("blocks/integer_bit_set.zig");
pub const LinearFifo = @import("blocks/linear_fifo.zig");
pub const MultiArrayList = @import("blocks/multi_array_list.zig");
pub const NetAddress = @import("blocks/net_address.zig");

/// `PackedIntArray` is a _Serialization Block_ for `std.PackedIntArray` values.
pub const PackedIntArray = _PackedIntEndian;

/// `PackedIntArrayEndian` is a _Serialization Block_ for `std.PackedIntArrayEndian` values.
pub const PackedIntArrayEndian = _PackedIntEndian;

/// `PackedIntSlice` is a _Serialization Block_ for `std.PackedIntSlice` values.
pub const PackedIntSlice = _PackedIntEndian;

/// `PackedIntSliceEndian` is a _Serialization Block_ for `std.PackedIntSliceEndian` values.
pub const PackedIntSliceEndian = _PackedIntEndian;

pub const PriorityDequeue = @import("blocks/priority_dequeue.zig");
pub const PriorityQueue = @import("blocks/priority_queue.zig");
pub const SegmentedList = @import("blocks/segmented_list.zig");
pub const SemanticVersion = @import("blocks/semantic_version.zig");
pub const SinglyLinkedList = @import("blocks/singly_linked_list.zig");
pub const StaticBitSet = @import("blocks/static_bit_set.zig");

/// `StringArrayHashMap` is a _Serialization Block_ for `std.StringArrayHashMap` values.
pub const StringArrayHashMap = _HashMap;

/// `StringArrayHashMapUnmanaged` is a _Serialization Block_ for `std.StringArrayHashMapUnmanaged` values.
pub const StringArrayHashMapUnmanaged = _HashMap;

/// `StringHashMap` is a _Serialization Block_ for `std.StringHashMap` values.
pub const StringHashMap = _HashMap;

/// `StringHashMapUnmanaged` is a _Serialization Block_ for `std.StringHashMapUnmanaged` values.
pub const StringHashMapUnmanaged = _HashMap;

pub const Uri = @import("blocks/uri.zig");

////////////////////////////////////////////////////////////////////////////////
// Aggregates
//
// All user-defined types must be listed BEFORE this section. Each type in this
// section has user-defined aliases that are supported by Getty (e.g.,
// `std.ArrayList` is a struct).
////////////////////////////////////////////////////////////////////////////////

pub const Struct = @import("blocks/struct.zig");
pub const Union = @import("blocks/union.zig");

////////////////////////////////////////////////////////////////////////////////
// Private
////////////////////////////////////////////////////////////////////////////////

const _ArrayListAligned = @import("blocks/array_list_aligned.zig");
const _EnumMultiset = @import("blocks/enum_multiset.zig");
const _HashMap = @import("blocks/hash_map.zig");
const _PackedIntEndian = @import("blocks/packed_int_endian.zig");
const _IndexedMap = @import("blocks/indexed_map.zig");
