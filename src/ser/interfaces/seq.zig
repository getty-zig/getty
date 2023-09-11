/// A `Seq` serializes the elements of and ends the serialization process for Getty Sequences.
pub fn Seq(
    /// An implementing type.
    comptime Impl: type,
    /// The successful return type of the interface's `end` method.
    comptime T: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        serializeElement: SerializeElementFn(Impl, E) = null,
        end: EndFn(Impl, T, E) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.ser.Seq" = struct {
            impl: Impl,

            const Self = @This();

            /// Successful return type.
            pub const Ok = T;

            /// The error set used upon failure.
            pub const Error = E;

            /// Serialize a sequence element.
            pub fn serializeElement(self: Self, elem: anytype) E!void {
                if (methods.serializeElement) |func| {
                    try func(self.impl, elem);
                } else {
                    @compileError("serializeElement is not implemented by type: " ++ @typeName(Impl));
                }
            }

            /// Finish serializing a sequence.
            pub fn end(self: Self) E!T {
                if (methods.end) |func| {
                    return try func(self.impl);
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

fn SerializeElementFn(comptime Impl: type, comptime Err: type) type {
    return ?fn (impl: Impl, elem: anytype) Err!void;
}

fn EndFn(comptime Impl: type, comptime Ok: type, comptime Err: type) type {
    return ?fn (impl: Impl) Err!Ok;
}
