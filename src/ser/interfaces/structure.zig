const ser = @import("../../lib.zig").ser;

/// Struct serialization interface.
///
/// Getty structs are only partially serialized by `getty.Serializer`
/// implementations due to the fact that there are many different ways to
/// iterate over and access the fields of a struct. As such, this interface is
/// provided so that serialization may be driven and completed by the user of a
/// serializer.
///
/// The interface specifies the following:
///
///     - How to serialize a field of a struct.
///     - How to finish serialization for a struct.
///
/// Parameters
/// ==========
///
///     Context
///     -------
///
///         This is the type that implements `getty.ser.Structure` (or a pointer to it).
///
///     Ok
///     --
///
///         The successful return type for all of `getty.ser.Structure`'s methods.
///
///     Error
///     -----
///
///         The error set used by all of `getty.ser.Structure`'s methods upon failure.
///
///     serializeField
///     --------------
///
///         A method that serializes a field of a struct.
///
///     end
///     ---
///
///         A method that ends the serialization of a struct.
///
/// Examples
/// ========
///
/// ```zig
/// const struct_sb = struct {
///     pub fn is(comptime T: type) bool {
///         return T == struct { x: i32, y: i32 };
///     }
///
///     pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
///         // Begin struct serialization.
///         const structure = (try serializer.serializeStruct("struct name", 2)).structure();
///
///         // Serialize struct fields.
///         try structure.serializeField("x", value.x);
///         try structure.serializeField("y", value.y);
///
///         // End struct serialization.
///         return try structure.end();
///     }
/// };
/// ```
pub fn Structure(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeField: @TypeOf(struct {
        fn f(self: Context, comptime key: []const u8, value: anytype) Error!void {
            _ = self;
            _ = key;
            _ = value;

            unreachable;
        }
    }.f),
    comptime end: fn (Context) Error!Ok,
) type {
    return struct {
        pub const @"getty.ser.Structure" = struct {
            context: Context,

            const Self = @This();

            /// Successful return type.
            pub const Ok = Ok;

            /// The error set used upon failure.
            pub const Error = Error;

            /// Serialize a struct field.
            pub fn serializeField(self: Self, comptime key: []const u8, value: anytype) Error!void {
                try serializeField(self.context, key, value);
            }

            /// Finish serializing a struct.
            pub fn end(self: Self) Error!Ok {
                return try end(self.context);
            }
        };

        pub fn structure(self: Context) @"getty.ser.Structure" {
            return .{ .context = self };
        }
    };
}
