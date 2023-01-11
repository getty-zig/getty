/// A `Structure` serializes the fields of and ends the serialization process for Getty Structures.
pub fn Structure(
    /// A namespace that owns the method implementations passed to the `methods` parameter.
    comptime Context: type,
    /// The successful return type of a `Structure`'s `end` method.
    comptime O: type,
    /// The error set returned by a `Structure`'s methods upon failure.
    comptime E: type,
    /// A namespace containing the methods that implementations of `Structure` can implement.
    comptime methods: struct {
        serializeField: ?fn (Context, comptime []const u8, anytype) E!void = null,
        end: ?fn (Context) E!O = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.ser.Structure" = struct {
            context: Context,

            const Self = @This();

            /// Successful return type.
            pub const Ok = O;

            /// The error set used upon failure.
            pub const Error = E;

            /// Serialize a struct field.
            pub fn serializeField(self: Self, comptime key: []const u8, value: anytype) Error!void {
                if (methods.serializeField) |f| {
                    try f(self.context, key, value);
                } else {
                    @compileError("serializeField is not implemented by type: " ++ @typeName(Context));
                }
            }

            /// Finish serializing a struct.
            pub fn end(self: Self) Error!Ok {
                if (methods.end) |f| {
                    try f(self.context);
                } else {
                    @compileError("end is not implemented by type: " ++ @typeName(Context));
                }
            }
        };

        /// Returns a `Structure` interface value.
        pub fn structure(self: Context) @"getty.ser.Structure" {
            return .{ .context = self };
        }
    };
}
