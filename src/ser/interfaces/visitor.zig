/// For custom serialization
pub fn Visitor(
    comptime Context: type,
    serializeFn: Fn(Context),
) type {
    return struct {
        context: Context,

        const Self = @This();

        pub fn serialize(self: Self, serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
            return try serializeFn(self.context, serializer, value);
        }
    };
}

fn Fn(comptime Context: type) type {
    const S = struct {
        fn f(self: Context, s: anytype, v: anytype) @TypeOf(s).Error!@TypeOf(s).Ok {
            _ = self;
            _ = v;

            unreachable;
        }
    };

    return @TypeOf(S.f);
}
