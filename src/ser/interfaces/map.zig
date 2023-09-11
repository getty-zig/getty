/// A `Map` serializes the entries of and ends the serialization process for Getty Maps.
pub fn Map(
    /// An implementing type.
    comptime Impl: type,
    /// The successful return type of the interface's `end` method.
    comptime T: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        serializeKey: SerializeKVFn(Impl, E) = null,
        serializeValue: SerializeKVFn(Impl, E) = null,
        serializeEntry: ?SerializeEntryFn(Impl, E) = null,
        end: EndFn(Impl, T, E) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.ser.Map" = struct {
            impl: Impl,

            const Self = @This();

            /// Successful return type.
            pub const Ok = T;

            /// The error set used upon failure.
            pub const Error = E;

            /// Serialize a map key.
            pub fn serializeKey(self: Self, key: anytype) E!void {
                if (methods.serializeKey) |func| {
                    try func(self.impl, key);
                } else {
                    @compileError("serializeKey is not implemented by type: " ++ @typeName(Impl));
                }
            }

            /// Serialize a map value.
            pub fn serializeValue(self: Self, value: anytype) E!void {
                if (methods.serializeValue) |func| {
                    try func(self.impl, value);
                } else {
                    @compileError("serializeValue is not implemented by type: " ++ @typeName(Impl));
                }
            }

            /// Serialize a map entry consisting of a key and a value.
            pub fn serializeEntry(self: Self, key: anytype, value: anytype) E!void {
                if (methods.serializeEntry) |func| {
                    try func(self.impl, key, value);
                } else {
                    try self.serializeKey(key);
                    try self.serializeValue(value);
                }
            }

            /// Finish serializing a struct.
            pub fn end(self: Self) E!T {
                if (methods.end) |func| {
                    return try func(self.impl);
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

fn SerializeKVFn(comptime Impl: type, comptime Err: type) type {
    return ?fn (impl: Impl, key: anytype) Err!void;
}

fn SerializeEntryFn(comptime Impl: type, comptime Err: type) type {
    return fn (impl: Impl, key: anytype, value: anytype) Err!void;
}

fn EndFn(comptime Impl: type, comptime Ok: type, comptime Err: type) type {
    return ?fn (impl: Impl) Err!Ok;
}
