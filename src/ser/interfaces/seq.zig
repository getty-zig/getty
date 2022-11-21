/// Serialization interface for Getty Sequences.
pub fn Seq(
    /// The namespace that owns the method implementations provided in `methods`.
    comptime Context: type,
    /// The successful return type of the interface's `end` method.
    comptime O: type,
    /// The error set returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace for the methods that implementations of the interface can implement.
    comptime methods: struct {
        serializeElement: ?fn (Context, anytype) E!void = null,
        end: ?fn (Context) E!O = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.ser.Seq" = struct {
            context: Context,

            const Self = @This();

            /// Successful return type.
            pub const Ok = O;

            /// The error set used upon failure.
            pub const Error = E;

            /// Serialize a sequence element.
            pub fn serializeElement(self: Self, value: anytype) Error!void {
                if (methods.serializeElement) |f| {
                    try f(self.context, value);
                } else {
                    @compileError("serializeElement is not implemented by type: " ++ @typeName(Context));
                }
            }

            /// Finish serializing a sequence.
            pub fn end(self: Self) Error!Ok {
                if (methods.end) |f| {
                    return try f(self.context);
                }

                @compileError("end is not implemented by type: " ++ @typeName(Context));
            }
        };

        /// Returns an interface value.
        pub fn seq(self: Context) @"getty.ser.Seq" {
            return .{ .context = self };
        }
    };
}
