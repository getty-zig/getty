/// A `Seq` serializes the elements of and ends the serialization process for Getty Sequences.
pub fn Seq(
    /// An implementing type.
    comptime Impl: type,
    /// The successful return type of a `Seq`'s `end` method.
    comptime O: type,
    /// The error set returned by a `Seq`'s methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        serializeElement: ?fn (Impl, anytype) E!void = null,
        end: ?fn (Impl) E!O = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.ser.Seq" = struct {
            impl: Impl,

            const Self = @This();

            /// Successful return type.
            pub const Ok = O;

            /// The error set used upon failure.
            pub const Error = E;

            /// Serialize a sequence element.
            pub fn serializeElement(self: Self, value: anytype) Error!void {
                if (methods.serializeElement) |f| {
                    try f(self.impl, value);
                } else {
                    @compileError("serializeElement is not implemented by type: " ++ @typeName(Impl));
                }
            }

            /// Finish serializing a sequence.
            pub fn end(self: Self) Error!Ok {
                if (methods.end) |f| {
                    return try f(self.impl);
                }

                @compileError("end is not implemented by type: " ++ @typeName(Impl));
            }
        };

        /// Returns a `Seq` interface value.
        pub fn seq(impl: Impl) @"getty.ser.Seq" {
            return .{ .impl = impl };
        }
    };
}
