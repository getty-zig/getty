const ser = @import("../../../lib.zig").ser;

/// Tuple serialization interface.
///
/// Getty tuples are only partially serialized by `getty.Serializer`
/// implementations due to the fact that there are many different ways to
/// iterate over and access the elements of a tuple. As such, this interface
/// is provided so that serialization may be driven and completed by the user
/// of a serializer.
///
/// The interface specifies the following:
///
///     - How to serialize an element of a tuple.
///     - How to finish serialization for a tuple.
///
/// Parameters
/// ==========
///
///     Context
///     -------
///
///         This is the type that implements `getty.ser.Tuple` (or a pointer to it).
///
///     Ok
///     --
///
///         The successful return type for all of `getty.ser.Tuple`'s methods.
///
///     Error
///     -----
///
///         The error set used by all of `getty.ser.Tuple`'s methods upon failure.
///
///     serializeElement
///     ----------------
///
///         A method that serializes an element of a tuple.
///
///         Callers of `getty.Serializer`'s `serializeTuple` method are expected
///         to use this function to serialize the elements of a tuple.
///
///     end
///     ---
///
///         A method that ends the serialization of a tuple.
///
///         Callers of `getty.Serializer`'s `serializeTuple` method are expected
///         to use this function to end the serialization of a tuple.
///
/// Examples
/// ========
///
/// ```zig
/// const Tuple = std.meta.Tuple(&.{i32, i32, i32});
///
/// const array_sb = struct {
///     pub fn is(comptime T: type) bool {
///         return T == std.meta.Tuple(Tuple);
///     }
///
///     pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
///         // Begin tuple serialization.
///         const seq = (try serializer.serializeTuple(5)).seq();
///
///         // Serialize tuple elements.
///         inline for (value) |elem| {
///             try seq.serializeElement(elem);
///         }
///
///         // End tuple serialization.
///         return try seq.end();
///     }
/// };
/// ```
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
