//! Sequence serialization interface.

const ser = @import("../../../lib.zig").ser;

/// Returns an anonymously namespaced interface function for sequence
/// serialization specifications.
pub fn SerializeSeq(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeElement: fn (Context, anytype) Error!void,
    comptime end: fn (Context) Error!Ok,
) type {
    return struct {
        pub const @"getty.ser.SerializeSeq" = struct {
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

        pub fn sequenceSerialize(self: Context) @"getty.ser.SerializeSeq" {
            return .{ .context = self };
        }
    };
}
