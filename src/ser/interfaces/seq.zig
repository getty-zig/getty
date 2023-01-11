/// A `Seq` serializes the elements of and ends the serialization process for Getty Sequences.
pub fn Seq(
    /// A namespace that owns the method implementations passed to the `methods` parameter.
    comptime Context: type,
    /// The successful return type of a `Seq`'s `end` method.
    comptime O: type,
    /// The error set returned by a `Seq`'s methods upon failure.
    comptime E: type,
    /// A namespace containing the methods that implementations of `Seq` can implement.
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

        /// Returns a `Seq` interface value.
        pub fn seq(self: Context) @"getty.ser.Seq" {
            return .{ .context = self };
        }
    };
}
