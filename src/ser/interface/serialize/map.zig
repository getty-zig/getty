//! Map serialization interface.

const ser = @import("../../../lib.zig").ser;

/// Returns an anonymously namespaced interface function for map serialization
/// specifications.
pub inline fn MapSerialize(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime keyFn: fn (Context, anytype) E!void,
    comptime valueFn: fn (Context, anytype) E!void,
    comptime entryFn: fn (Context, anytype, anytype) E!void,
    comptime endFn: fn (Context) E!O,
) type {
    switch (@typeInfo(E)) {
        .ErrorSet => {},
        else => @compileError("expected error set, found `" ++ @typeName(E) ++ "`"),
    }

    return _MapSerialize(
        Context,
        O,
        E || ser.Error,
        keyFn,
        valueFn,
        entryFn,
        endFn,
    );
}

fn _MapSerialize(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime keyFn: fn (Context, anytype) E!void,
    comptime valueFn: fn (Context, anytype) E!void,
    comptime entryFn: fn (Context, anytype, anytype) E!void,
    comptime endFn: fn (Context) E!O,
) type {
    const T = struct {
        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        context: Context,

        /// Serialize a map key.
        pub fn serializeKey(self: Self, key: anytype) Error!void {
            try keyFn(self.context, key);
        }

        /// Serialize a map value.
        pub fn serializeValue(self: Self, value: anytype) Error!void {
            try valueFn(self.context, value);
        }

        /// Serialize a map entry consisting of a key and a value.
        pub fn serializeEntry(self: Self, key: anytype, value: anytype) Error!void {
            try entryFn(self.context, key, value);
        }

        /// Finish serializing a struct.
        pub fn end(self: Self) Error!Ok {
            return try endFn(self.context);
        }
    };

    return struct {
        pub fn mapSerialize(self: Context) T {
            return .{ .context = self };
        }
    };
}
