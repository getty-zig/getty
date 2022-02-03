//! Structure serialization interface.

const ser = @import("../../../lib.zig").ser;

/// Returns an anonymously namespaced interface function for struct
/// serialization specifications.
pub fn Structure(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeField: @TypeOf(struct {
        fn f(self: Context, comptime key: []const u8, value: anytype) Error!void {
            _ = self;
            _ = key;
            _ = value;

            unreachable;
        }
    }.f),
    comptime end: fn (Context) Error!Ok,
) type {
    return struct {
        pub const @"getty.ser.Structure" = struct {
            context: Context,

            const Self = @This();

            /// Successful return type.
            pub const Ok = Ok;

            /// The error set used upon failure.
            pub const Error = Error;

            /// Serialize a struct field.
            pub fn serializeField(self: Self, comptime key: []const u8, value: anytype) Error!void {
                try serializeField(self.context, key, value);
            }

            /// Finish serializing a struct.
            pub fn end(self: Self) Error!Ok {
                return try end(self.context);
            }
        };

        pub fn structure(self: Context) @"getty.ser.Structure" {
            return .{ .context = self };
        }
    };
}
