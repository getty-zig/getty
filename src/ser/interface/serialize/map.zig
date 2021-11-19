//! Map serialization interface.

const ser = @import("../../../lib.zig").ser;

/// Returns an anonymously namespaced interface function for map serialization
/// specifications.
pub fn MapSerialize(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeKey: fn (Context, anytype) Error!void,
    comptime serializeValue: fn (Context, anytype) Error!void,
    comptime end: fn (Context) Error!Ok,
) type {
    switch (@typeInfo(Error)) {
        .ErrorSet => {},
        else => @compileError("expected error set, found `" ++ @typeName(Error) ++ "`"),
    }

    const T = struct {
        context: Context,

        const Self = @This();

        /// Successful return type.
        pub const Ok = Ok;

        /// The error set used upon failure.
        pub const Error = Error;

        /// Serialize a map key.
        pub fn serializeKey(self: Self, key: anytype) Error!void {
            try serializeKey(self.context, key);
        }

        /// Serialize a map value.
        pub fn serializeValue(self: Self, value: anytype) Error!void {
            try serializeValue(self.context, value);
        }

        /// Serialize a map entry consisting of a key and a value.
        pub fn serializeEntry(self: Self, key: anytype, value: anytype) Error!void {
            try self.serializeKey(key);
            try self.serializeValue(value);
        }

        /// Finish serializing a struct.
        pub fn end(self: Self) Error!Ok {
            return try end(self.context);
        }
    };

    return struct {
        pub fn mapSerialize(self: Context) T {
            return .{ .context = self };
        }
    };
}
