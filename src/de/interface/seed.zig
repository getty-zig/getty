pub fn DeserializeSeed(
    comptime Context: type,
    comptime V: type,
    comptime deserializeFn: @TypeOf(struct {
        fn f(c: Context, d: anytype) @TypeOf(d).Error!V {
            _ = c;
            unreachable;
        }
    }.f),
) type {
    const T = struct {
        context: Context,

        const Self = @This();

        pub const Value = V;

        pub fn deserialize(self: Self, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try deserializeFn(self.context, deserializer);
        }
    };

    return struct {
        pub fn deserializeSeed(self: Context) T {
            return .{ .context = self };
        }
    };
}
