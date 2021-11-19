//! Sequence serialization interface.

const ser = @import("../../../lib.zig").ser;

/// Returns an anonymously namespaced interface function for sequence
/// serialization specifications.
pub fn SequenceSerialize(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeElement: fn (Context, anytype) Error!void,
    comptime end: fn (Context) Error!Ok,
) type {
    switch (@typeInfo(Error)) {
        .ErrorSet => {},
        else => @compileError("expected error set, found `" ++ @typeName(Error) ++ "`"),
    }

    const T = struct {
        context: Context,

        const Self = @This();

        /// Successful return type.
        pub const Ok = Ok;

        /// The error set used upon failure.
        pub const Error = Error;

        /// Serialize a sequence element.
        pub fn serializeElement(self: Self, value: anytype) Error!void {
            try serializeElement(self.context, value);
        }

        /// Finish serializing a sequence.
        pub fn end(self: Self) Error!Ok {
            return try end(self.context);
        }
    };

    return struct {
        pub fn sequenceSerialize(self: Context) T {
            return .{ .context = self };
        }
    };
}
