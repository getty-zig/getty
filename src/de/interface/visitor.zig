const Allocator = @import("std").mem.Allocator;
const assert = @import("std").debug.assert;

pub fn Visitor(
    comptime Context: type,
    comptime V: type,
    comptime boolFn: @TypeOf(struct {
        fn f(self: Context, comptime Error: type, input: bool) Error!V {
            _ = self;
            _ = input;
            unreachable;
        }
    }.f),
    comptime enumFn: @TypeOf(struct {
        fn f(self: Context, comptime Error: type, input: anytype) Error!V {
            _ = self;
            _ = input;
            unreachable;
        }
    }.f),
    comptime floatFn: @TypeOf(struct {
        fn f(self: Context, comptime Error: type, input: anytype) Error!V {
            _ = self;
            _ = input;
            unreachable;
        }
    }.f),
    comptime intFn: @TypeOf(struct {
        fn f(self: Context, comptime Error: type, input: anytype) Error!V {
            _ = self;
            _ = input;
            unreachable;
        }
    }.f),
    comptime mapFn: @TypeOf(struct {
        fn f(self: Context, mapAccess: anytype) @TypeOf(mapAccess).Error!V {
            _ = self;
            _ = mapAccess;
            unreachable;
        }
    }.f),
    comptime nullFn: @TypeOf(struct {
        fn f(self: Context, comptime Error: type) Error!V {
            _ = self;
            unreachable;
        }
    }.f),
    comptime sequenceFn: @TypeOf(struct {
        fn f(self: Context, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!V {
            _ = self;
            _ = sequenceAccess;
            unreachable;
        }
    }.f),
    comptime sliceFn: @TypeOf(struct {
        fn f(self: Context, allocator: *Allocator, comptime E: type, input: anytype) E!V {
            _ = self;
            _ = allocator;
            _ = input;
            unreachable;
        }
    }.f),
    comptime someFn: @TypeOf(struct {
        fn f(self: Context, allocator: ?*Allocator, deserializer: anytype) @TypeOf(deserializer).Error!V {
            _ = self;
            _ = allocator;
            unreachable;
        }
    }.f),
    comptime voidFn: @TypeOf(struct {
        fn f(self: Context, comptime Error: type) Error!V {
            _ = self;
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
