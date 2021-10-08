//! Struct serialization interface.

const ser = @import("../../../lib.zig").ser;

/// Returns an anonymously namespaced interface function for struct
/// serialization specifications.
pub fn StructSerialize(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime fieldFn: fn (Context, comptime []const u8, anytype) E!void,
    comptime endFn: fn (Context) E!O,
) type {
    switch (@typeInfo(E)) {
        .ErrorSet => {},
        else => @compileError("expected error set, found `" ++ @typeName(E) ++ "`"),
    }

    const T = struct {
        context: Context,

        const Self = @This();

        /// Successful return type.
        pub const Ok = O;

        /// The error set used upon failure.
        pub const Error = E;

        /// Serialize a struct field.
        pub fn serializeField(self: Self, comptime key: []const u8, value: anytype) Error!void {
            try fieldFn(self.context, key, value);
        }

        /// Finish serializing a struct.
        pub fn end(self: Self) Error!Ok {
            return try endFn(self.context);
        }
    };

    return struct {
        pub fn structSerialize(self: Context) T {
            return .{ .context = self };
        }
    };
}
