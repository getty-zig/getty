//! Sequence serialization interface.

const ser = @import("../../../lib.zig").ser;

/// Returns an anonymously namespaced interface function for sequence
/// serialization specifications.
pub fn SequenceSerialize(
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

        /// Serialize a sequence element.
        pub fn serializeElement(self: Self, value: anytype) Error!void {
            try elementFn(self.context, value);
        }

        /// Finish serializing a sequence.
        pub fn end(self: Self) Error!Ok {
            return try endFn(self.context);
        }
    };

    return struct {
        pub fn sequenceSerialize(self: Context) T {
            return .{ .context = self };
        }
    };
}
