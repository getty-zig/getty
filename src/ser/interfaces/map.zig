/// A `Map` serializes the entries of and ends the serialization process for Getty Maps.
pub fn Map(
    /// An implementing type.
    comptime Impl: type,
    /// The successful return type of a `Map`'s `end` method.
    comptime O: type,
    /// The error set returned by a `Map`'s methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        serializeKey: ?fn (Impl, anytype) E!void = null,
        serializeValue: ?fn (Impl, anytype) E!void = null,
        serializeEntry: ?fn (Impl, anytype, anytype) E!void = null,
        end: ?fn (Impl) E!O = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.ser.Map" = struct {
            impl: Impl,

            const Self = @This();

            /// Successful return type.
            pub const Ok = O;

            /// The error set used upon failure.
            pub const Error = E;

            /// Serialize a map key.
            pub fn serializeKey(self: Self, key: anytype) Error!void {
                if (methods.serializeKey) |f| {
                    try f(self.impl, key);
                } else {
                    @compileError("serializeKey is not implemented by type: " ++ @typeName(Impl));
                }
            }

            /// Serialize a map value.
            pub fn serializeValue(self: Self, value: anytype) Error!void {
                if (methods.serializeValue) |f| {
                    try f(self.impl, value);
                } else {
                    @compileError("serializeValue is not implemented by type: " ++ @typeName(Impl));
                }
            }

            /// Serialize a map entry consisting of a key and a value.
            pub fn serializeEntry(self: Self, key: anytype, value: anytype) Error!void {
                if (methods.serializeEntry) |f| {
                    try f(self.impl, key, value);
                } else {
                    try self.serializeKey(key);
                    try self.serializeValue(value);
                }
            }

            /// Finish serializing a struct.
            pub fn end(self: Self) Error!Ok {
                if (methods.end) |f| {
                    return try f(self.impl);
                }

                @compileError("end is not implemented by type: " ++ @typeName(Impl));
            }
        };

        /// Returns a `Map` interface value.
        pub fn map(impl: Impl) @"getty.ser.Map" {
            return .{ .impl = impl };
        }
    };
}
