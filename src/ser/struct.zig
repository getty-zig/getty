pub fn Structure(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime fieldFn: fn (Context, comptime []const u8, anytype) E!void,
    comptime endFn: fn (Context) E!O,
) type {
    return struct {
        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        context: Context,

        /// Serialize a struct field.
        pub fn serializeField(self: Self, comptime key: []const u8, value: anytype) Error!void {
            try fieldFn(self.context, key, value);
        }

        /// Finish serializing a struct.
        pub fn end(self: Self) Error!Ok {
            return try endFn(self.context);
        }
    };
}
