/// Serialization interface for Getty Maps.
pub fn Map(
    /// The namespace that owns the method implementations provided in `methods`.
    comptime Context: type,
    /// The successful return type of the interface's `end` method.
    comptime O: type,
    /// The error set returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace for the methods that implementations of the interface can implement.
    comptime methods: struct {
        serializeKey: ?fn (Context, anytype) E!void = null,
        serializeValue: ?fn (Context, anytype) E!void = null,
        serializeEntry: ?fn (Context, anytype, anytype) E!void = null,
        end: ?fn (Context) E!O = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.ser.Map" = struct {
            context: Context,

            const Self = @This();

            /// Successful return type.
            pub const Ok = O;

            /// The error set used upon failure.
            pub const Error = E;

            /// Serialize a map key.
            pub fn serializeKey(self: Self, key: anytype) Error!void {
                if (methods.serializeKey) |f| {
                    try f(self.context, key);
                } else {
                    @compileError("serializeKey is not implemented by type: " ++ @typeName(Context));
                }
            }

            /// Serialize a map value.
            pub fn serializeValue(self: Self, value: anytype) Error!void {
                if (methods.serializeValue) |f| {
                    try f(self.context, value);
                } else {
                    @compileError("serializeValue is not implemented by type: " ++ @typeName(Context));
                }
            }

            /// Serialize a map entry consisting of a key and a value.
            pub fn serializeEntry(self: Self, key: anytype, value: anytype) Error!void {
                if (methods.serializeEntry) |f| {
                    try f(self.context, key, value);
                } else {
                    try self.serializeKey(key);
                    try self.serializeValue(value);
                }
            }

            /// Finish serializing a struct.
            pub fn end(self: Self) Error!Ok {
                if (methods.end) |f| {
                    return try f(self.context);
                }

                @compileError("end is not implemented by type: " ++ @typeName(Context));
            }
        };

        /// Returns an interface value.
        pub fn map(self: Context) @"getty.ser.Map" {
            return .{ .context = self };
        }
    };
}
