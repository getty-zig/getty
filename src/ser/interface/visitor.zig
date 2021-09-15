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
    serializeFn: Fn(Context),
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

fn Fn(comptime Context: type) type {
    const S = struct {
        fn f(self: Context, v: anytype, s: anytype) @TypeOf(s).Error!@TypeOf(s).Ok {
            _ = self;
            _ = v;

            unreachable;
        }
    };

    return @TypeOf(S.f);
}
