/// A `Structure` serializes the fields of and ends the serialization process for Getty Structures.
pub fn Structure(
    /// An implementing type.
    comptime Impl: type,
    /// The successful return type of a `Structure`'s `end` method.
    comptime O: type,
    /// The error set returned by a `Structure`'s methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        serializeField: ?fn (Impl, comptime []const u8, anytype) E!void = null,
        end: ?fn (Impl) E!O = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.ser.Structure" = struct {
            impl: Impl,

            const Self = @This();

            /// Successful return type.
            pub const Ok = O;

            /// The error set used upon failure.
            pub const Error = E;

            /// Serialize a struct field.
            pub fn serializeField(self: Self, comptime key: []const u8, value: anytype) Error!void {
                if (methods.serializeField) |f| {
                    try f(self.impl, key, value);
                } else {
                    @compileError("serializeField is not implemented by type: " ++ @typeName(Impl));
                }
            }

            /// Finish serializing a struct.
            pub fn end(self: Self) Error!Ok {
                if (methods.end) |f| {
                    return try f(self.impl);
                } else {
                    @compileError("end is not implemented by type: " ++ @typeName(Impl));
                }
            }
        };

        /// Returns a `Structure` interface value.
        pub fn structure(impl: Impl) @"getty.ser.Structure" {
            return .{ .impl = impl };
        }
    };
}
