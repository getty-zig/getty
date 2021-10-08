//! Tuple serialization interface.

const ser = @import("../../../lib.zig").ser;

/// Returns an anonymously namespaced interface function for tuple
/// serialization specifications.
pub fn TupleSerialize(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime elementFn: fn (Context, anytype) E!void,
    comptime endFn: fn (Context) E!O,
) type {
    switch (@typeInfo(E)) {
        .ErrorSet => {},
        else => @compileError("expected error set, found `" ++ @typeName(E) ++ "`"),
    }

    const T = struct {
        context: Context,

        const Self = @This();

        /// Successful return type.
        pub const Ok = O;

        /// The error set used upon failure.
        pub const Error = E;

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
