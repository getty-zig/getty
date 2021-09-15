//! Serialization visitor interface.
//!
//! Visitors define how to convert Zig data types into Getty's data model.
//!
//! Using this interface, custom serialization logic may be written and used
//! for any Zig data type, regardless of whether or not they are supported by
//! Getty. For example, `std.ArrayList` is not supported by Getty due to its
//! `allocator` field, which consists of function pointers, which aren't
//! serializable. However, you can easily serialize a `std.ArrayList` by
//! creating a visitor that serializes the slice maintained by the
//! `std.ArrayList` instead of the `std.ArrayList` struct itself.

/// Returns a namespace containing an interface function for visitors.
pub fn Visitor(
    comptime Context: type,
    serializeFn: @TypeOf(struct {
        fn f(self: Context, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
            _ = self;
            _ = value;
            _ = serializer;

            unreachable;
        }
    }.f),
) type {
    const T = struct {
        context: Context,

        const Self = @This();

        /// A specification of how to serialize `value`.
        pub fn serialize(self: Self, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
            return try serializeFn(self.context, value, serializer);
        }
    };

    return struct {
        pub fn visitor(self: Context) T {
            return .{ .context = self };
        }
    };
}
