const ser = @import("../../../lib.zig").ser;

/// Sequence serialization interface.
///
/// Getty sequences are only partially serialized by `getty.Serializer`
/// implementations due to the fact that there are many different ways to
/// iterate over and access the elements of a sequence. As such, this interface
/// is provided so that serialization may be driven and completed by the user
/// of a serializer.
///
/// The interface specifies the following:
///
///     - How to serialize an element of a sequence.
///     - How to finish serialization for a sequence.
///
/// Parameters
/// ==========
///
///     Context
///     -------
///
///         This is the type that implements `getty.ser.Seq` (or a pointer to it).
///
///     Ok
///     --
///
///         The successful return type for all of `getty.ser.Seq`'s methods.
///
///     Error
///     -----
///
///         The error set used by all of `getty.ser.Seq`'s methods upon failure.
///
///     serializeElement
///     ----------------
///
///         A method that serializes an element of a sequence.
///
///     end
///     ---
///
///         A method that ends the serialization of a sequence.
///
/// Examples
/// ========
///
/// ```zig
/// const seq_sb = struct {
///     pub fn is(comptime T: type) bool {
///         return T == [3]i32;
///     }
///
///     pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
///         // Begin sequence serialization.
///         const seq = (try serializer.serializeSeq(3)).seq();
///
///         // Serialize sequence elements.
///         for (value) |elem| {
///             try seq.serializeElement(elem);
///         }
///
///         // End sequence serialization.
///         return try seq.end();
///     }
/// };
/// ```
pub fn Seq(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeElement: fn (Context, anytype) Error!void,
    comptime end: fn (Context) Error!Ok,
) type {
    return struct {
        pub const @"getty.ser.Seq" = struct {
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

        pub fn seq(self: Context) @"getty.ser.Seq" {
            return .{ .context = self };
        }
    };
}
