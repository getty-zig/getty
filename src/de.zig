const std = @import("std");

fn DeserializerFn(comptime Context: type, comptime Error: type) type {
    return @TypeOf(struct {
        fn f(context: Context, visitor: anytype) Error!@TypeOf(visitor).Ok {
            unreachable;
        }
    }.f);
}

/// An interface for deserializing input into Getty's data model.
pub fn Deserializer(
    comptime Context: type,
    comptime E: type,
    //comptime anyFn: DeserializerFn(Context, E),
    comptime boolFn: DeserializerFn(Context, E),
    comptime intFn: DeserializerFn(Context, E),
    //comptime floatFn: DeserializerFn(Context, E),
    //comptime optionFn: DeserializerFn(Context, E),
    //comptime sequenceFn: DeserializerFn(Context, E),
    //comptime stringFn: DeserializerFn(Context, E),
    //comptime structFn: DeserializerFn(Context, E),
    //comptime variantFn: DeserializerFn(Context, E),
) type {
    return struct {
        context: Context,

        const Self = @This();

        pub const Error = E;

        //pub fn deserializeAny(self: Self, visitor: anytype) E!@TypeOf(visitor).Ok {
        //return try anyFn(self.context, visitor);
        //}

        pub fn deserializeBool(self: Self, visitor: anytype) E!@TypeOf(visitor).Ok {
            return try boolFn(self.context, visitor);
        }

        pub fn deserializeInt(self: Self, visitor: anytype) E!@TypeOf(visitor).Ok {
            return try intFn(self.context, visitor);
        }

        //pub fn deserializeFloat(self: Self, visitor: anytype) E!@TypeOf(visitor).Ok {
        //return try floatFn(self.context, visitor);
        //}

        //pub fn deserializeOption(self: Self, visitor: anytype) E!@TypeOf(visitor).Ok {
        //return try optionFn(self.context, visitor);
        //}

        //pub fn deserializeSequence(self: Self, visitor: anytype) E!@TypeOf(visitor).Ok {
        //return try sequenceFn(self.context, visitor);
        //}

        //pub fn deserializeString(self: Self, visitor: anytype) E!@TypeOf(visitor).Ok {
        //return try stringFn(self.context, visitor);
        //}

        //pub fn deserializeStruct(self: Self, visitor: anytype) E!@TypeOf(visitor).Ok {
        //return try structFn(self.context, visitor);
        //}

        //pub fn deserializeVariant(self: Self, visitor: anytype) E!@TypeOf(visitor).Ok {
        //return try variantFn(self.context, visitor);
        //}
    };
}

/// An interface for deserializing Getty data types into higher-level,
/// user-defined types.
pub fn Visitor(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime boolFn: fn (Context, bool) E!O,
    comptime intFn: fn (Context, anytype) E!O,
    //comptime floatFn: fn (Context, anytype) E!O,
    //comptime nullFn: fn (Context, anytype) E!O,
    //comptime someFn: fn (Context, anytype) E!O,
    //comptime sequenceFn: fn (Context, anytype) E!O,
    //comptime stringFn: fn (Context, anytype) E!O,
    //comptime structFn: fn (Context, anytype) E!O,
    //comptime variantFn: fn (Context, anytype) E!O,
) type {
    return struct {
        context: Context,

        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        pub fn visitBool(self: Self, value: bool) E!O {
            return try boolFn(self.context, value);
        }

        pub fn visitInt(self: Self, value: anytype) E!O {
            return try intFn(self.context, value);
        }

        //pub fn visitFloat(self: Self, value: anytype) E!O {
        //return try floatFn(self.context, value);
        //}

        //pub fn visitNull(self: Self, value: anytype) E!O {
        //return try nullFn(self.context, value);
        //}

        //pub fn visitSome(self: Self, value: anytype) E!O {
        //return try someFn(self.context, value);
        //}

        //pub fn visitSequence(self: Self, value: anytype) E!O {
        //return try sequenceFn(self.context, value);
        //}

        //pub fn visitString(self: Self, value: anytype) E!O {
        //return try stringFn(self.context, value);
        //}

        //pub fn visitStruct(self: Self, value: anytype) E!O {
        //return try structFn(self.context, value);
        //}

        //pub fn visitVariant(self: Self, value: anytype) E!O {
        //return try variantFn(self.context, value);
        //}
    };
}

comptime {
    std.testing.refAllDecls(@This());
}
