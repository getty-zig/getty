//! Tuple serialization interface.

/// Returns a namespace containing an interface function for tuple
/// serialization specifications.
pub fn TupleSerialize(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime elementFn: fn (Context, anytype) E!void,
    comptime endFn: fn (Context) E!O,
) type {
    const T = struct {
        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        context: Context,

        /// Serialize a tuple element.
        pub fn serializeElement(self: Self, value: anytype) Error!void {
            try elementFn(self.context, value);
        }

        /// Finish serializing a tuple.
        pub fn end(self: Self) Error!Ok {
            return try endFn(self.context);
        }
    };

    return struct {
        pub fn tupleSerialize(self: Context) T {
            return .{ .context = self };
        }
    };
}
