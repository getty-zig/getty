const Allocator = @import("std").mem.Allocator;
const assert = @import("std").debug.assert;

pub fn Visitor(
    comptime Context: type,
    comptime V: type,
    comptime boolFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type, v: bool) Error!V {
            _ = c;
            _ = v;
            unreachable;
        }
    }.f),
    comptime enumFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type, v: anytype) Error!V {
            _ = c;
            _ = v;
            unreachable;
        }
    }.f),
    comptime floatFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type, v: anytype) Error!V {
            _ = c;
            _ = v;
            unreachable;
        }
    }.f),
    comptime intFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type, v: anytype) Error!V {
            _ = c;
            _ = v;
            unreachable;
        }
    }.f),
    comptime mapFn: @TypeOf(struct {
        fn f(c: Context, m: anytype) @TypeOf(m).Error!V {
            _ = c;
            _ = m;
            unreachable;
        }
    }.f),
    comptime nullFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type) Error!V {
            _ = c;
            unreachable;
        }
    }.f),
    comptime sequenceFn: @TypeOf(struct {
        fn f(c: Context, s: anytype) @TypeOf(s).Error!V {
            _ = c;
            _ = s;
            unreachable;
        }
    }.f),
    comptime sliceFn: @TypeOf(struct {
        fn f(c: Context, a: *Allocator, comptime E: type, input: anytype) E!V {
            _ = c;
            _ = a;
            _ = input;
            unreachable;
        }
    }.f),
    comptime someFn: @TypeOf(struct {
        fn f(c: Context, a: ?*Allocator, d: anytype) @TypeOf(d).Error!V {
            _ = c;
            _ = a;
            unreachable;
        }
    }.f),
    comptime voidFn: @TypeOf(struct {
        fn f(c: Context, comptime Error: type) Error!V {
            _ = c;
            unreachable;
        }
    }.f),
) type {
    const T = struct {
        context: Context,

        const Self = @This();

        pub const Value = V;

        pub fn visitBool(self: Self, comptime Error: type, input: bool) Error!Value {
            return try boolFn(self.context, Error, input);
        }

        pub fn visitFloat(self: Self, comptime Error: type, input: anytype) Error!Value {
            comptime assert(@typeInfo(@TypeOf(input)) == .Float or @typeInfo(@TypeOf(input)) == .ComptimeFloat);

            return try floatFn(self.context, Error, input);
        }

        pub fn visitInt(self: Self, comptime Error: type, input: anytype) Error!Value {
            comptime assert(@typeInfo(@TypeOf(input)) == .Int or @typeInfo(@TypeOf(input)) == .ComptimeInt);

            return try intFn(self.context, Error, input);
        }

        pub fn visitMap(self: Self, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            return try mapFn(self.context, mapAccess);
        }

        pub fn visitNull(self: Self, comptime Error: type) Error!Value {
            return try nullFn(self.context, Error);
        }

        pub fn visitSequence(self: Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
            return try sequenceFn(self.context, sequenceAccess);
        }

        pub fn visitSlice(self: Self, allocator: *Allocator, comptime Error: type, input: anytype) Error!Value {
            return try sliceFn(self.context, allocator, Error, input);
        }

        // TODO: what is the point of visitSome?
        pub fn visitSome(self: Self, allocator: ?*Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try someFn(self.context, allocator, deserializer);
        }

        pub fn visitEnum(self: Self, comptime Error: type, input: anytype) Error!Value {
            return try enumFn(self.context, Error, input);
        }

        pub fn visitVoid(self: Self, comptime Error: type) Error!Value {
            return try voidFn(self.context, Error);
        }
    };

    return struct {
        pub fn visitor(self: Context) T {
            return .{ .context = self };
        }
    };
}
