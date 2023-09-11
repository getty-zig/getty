/// A `Structure` serializes the fields of and ends the serialization process for Getty Structures.
pub fn Structure(
    /// An implementing type.
    comptime Impl: type,
    /// The successful return type of the interface's `end` method.
    comptime T: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        serializeField: SerializeFieldFn(Impl, E) = null,
        end: EndFn(Impl, T, E) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.ser.Structure" = struct {
            impl: Impl,

            const Self = @This();

            /// Successful return type.
            pub const Ok = T;

            /// The error set used upon failure.
            pub const Error = E;

            /// Serialize a struct field.
            pub fn serializeField(self: Self, comptime key: []const u8, value: anytype) E!void {
                if (methods.serializeField) |func| {
                    try func(self.impl, key, value);
                } else {
                    @compileError("serializeField is not implemented by type: " ++ @typeName(Impl));
                }
            }

            /// Finish serializing a struct.
            pub fn end(self: Self) E!T {
                if (methods.end) |func| {
                    return try func(self.impl);
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

fn SerializeFieldFn(comptime Impl: type, comptime Err: type) type {
    return ?fn (impl: Impl, comptime key: []const u8, value: anytype) Err!void;
}

fn EndFn(comptime Impl: type, comptime Ok: type, comptime Err: type) type {
    return ?fn (impl: Impl) Err!Ok;
}
