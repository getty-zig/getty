/// Map serialization interface.
///
/// Getty maps are only partially serialized by `getty.Serializer`
/// implementations due to the fact that there are many different ways to
/// iterate over and access the keys and values of a map. As such, this
/// interface is provided so that serialization may be driven and completed by
/// the user of a serializer.
///
/// The interface specifies the following:
///
///     - How to serialize a key of a map.
///     - How to serialize a value of a map.
///     - How to finish serialization for a map.
///
/// Parameters
/// ==========
///
///     Context
///     -------
///
///         This is the type that implements `getty.ser.Map` (or a pointer to it).
///
///     O
///     -
///
///         The successful return type for all of `getty.ser.Map`'s methods.
///
///     E
///     -
///
///         The error set used by all of `getty.ser.Map`'s methods upon failure.
///
///     serializeKey
///     ------------
///
///         A method that serializes a key of a map.
///
///     serializeValue
///     --------------
///
///         A method that serializes a value of a map.
///
///     end
///     ---
///
///         A method that ends the serialization of a map.
///
/// Examples
/// ========
///
/// ```zig
/// const map_sb = struct {
///     pub fn is(comptime T: type) bool {
///         return T == struct { x: i32, y: i32 };
///     }
///
///     pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
///         // Begin map serialization.
///         const map = (try serializer.serializeMap(2)).map();
///
///         // Serialize map entries.
///         try map.serializeKey("x");
///         try map.serializeValue(map.x);
///         try map.serializeKey("y");
///         try map.serializeValue(map.y);
///
///         // End map serialization.
///         return try map.end();
///     }
/// };
/// ```
pub fn Map(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime impls: struct {
        serializeKey: ?fn (Context, anytype) E!void = null,
        serializeValue: ?fn (Context, anytype) E!void = null,
        serializeEntry: ?fn (Context, anytype, anytype) E!void = null,
        end: ?fn (Context) E!O = null,
    },
) type {
    return struct {
        pub const @"getty.ser.Map" = struct {
            context: Context,

            const Self = @This();

            /// Successful return type.
            pub const Ok = O;

            /// The error set used upon failure.
            pub const Error = E;

            /// Serialize a map key.
            pub fn serializeKey(self: Self, key: anytype) Error!void {
                if (impls.serializeKey) |f| {
                    try f(self.context, key);
                } else {
                    @compileError("serializeKey is not implemented by type: " ++ @typeName(Context));
                }
            }

            /// Serialize a map value.
            pub fn serializeValue(self: Self, value: anytype) Error!void {
                if (impls.serializeValue) |f| {
                    try f(self.context, value);
                } else {
                    @compileError("serializeValue is not implemented by type: " ++ @typeName(Context));
                }
            }

            /// Serialize a map entry consisting of a key and a value.
            pub fn serializeEntry(self: Self, key: anytype, value: anytype) Error!void {
                if (impls.serializeEntry) |f| {
                    try f(self.context, key, value);
                } else {
                    try self.serializeKey(key);
                    try self.serializeValue(value);
                }
            }

            /// Finish serializing a struct.
            pub fn end(self: Self) Error!Ok {
                if (impls.end) |f| {
                    return try f(self.context);
                }

                @compileError("end is not implemented by type: " ++ @typeName(Context));
            }
        };

        pub fn map(self: Context) @"getty.ser.Map" {
            return .{ .context = self };
        }
    };
}
