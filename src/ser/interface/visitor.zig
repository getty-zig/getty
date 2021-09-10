/// For custom serialization
pub fn Visitor(
    comptime Context: type,
    serializeFn: Fn(Context),
) type {
    const T = struct {
        context: Context,

        const Self = @This();

        pub fn serialize(self: Self, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
            return try serializeFn(self.context, value, serializer);
        }
    };

    return struct {
        pub fn visitor(self: Context) T {
            return .{ .context = self };
        }
    };
}

fn Fn(comptime Context: type) type {
    const S = struct {
        fn f(self: Context, v: anytype, s: anytype) @TypeOf(s).Error!@TypeOf(s).Ok {
            _ = self;
            _ = v;

            unreachable;
        }
    };

    return @TypeOf(S.f);
}
