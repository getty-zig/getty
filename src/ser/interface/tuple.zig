//! Tuple serialization interface.

const ser = @import("../../../lib.zig").ser;

/// Returns an anonymously namespaced interface function for tuple
/// serialization specifications.
pub fn Tuple(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeElement: fn (Context, anytype) Error!void,
    comptime end: fn (Context) Error!Ok,
) type {
    return struct {
        pub const @"getty.ser.Tuple" = struct {
            context: Context,

            const Self = @This();

            /// Successful return type.
            pub const Ok = Ok;

            /// The error set used upon failure.
            pub const Error = Error;

            /// Serialize a tuple element.
            pub fn serializeElement(self: Self, value: anytype) Error!void {
                try serializeElement(self.context, value);
            }

            /// Finish serializing a tuple.
            pub fn end(self: Self) Error!Ok {
                return try end(self.context);
            }
        };

        pub fn tuple(self: Context) @"getty.ser.Tuple" {
            return .{ .context = self };
        }
    };
}
