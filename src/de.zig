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

const TestDeserializer = struct {
    input: []const u8,

    const Self = @This();

    pub const Error = error{DeserializationError};

    /// Implements `getty.de.Deserializer`.
    pub const D = Deserializer(
        *Self,
        Error,
        deserializeBool,
        deserializeInt,
    );

    pub fn deserializer(self: *Self) D {
        return .{ .context = self };
    }

    /// Implements `boolFn` for `getty.de.Deserializer`.
    pub fn deserializeBool(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
        if (std.mem.eql(u8, self.input, "true")) {
            return visitor.visitBool(true) catch return Error.DeserializationError;
        } else if (std.mem.eql(u8, self.input, "false")) {
            return visitor.visitBool(false) catch return Error.DeserializationError;
        }

        return Error.DeserializationError;
    }

    /// Implements `intFn` for `getty.de.Deserializer`.
    pub fn deserializeInt(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
        const value = std.json.parse(i64, &std.json.TokenStream.init(self.input), .{}) catch return Error.DeserializationError;
        return visitor.visitInt(value) catch return Error.DeserializationError;
    }

    // TODO: How do we know what size float to parse from the input?
    //pub fn deserializeFloat(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
    //const value: f64 = parseFloat(f64, self.input) catch unreachable;
    //return visitor.visitFloat(value) catch return Error.DeserializationError;
    //}

    //pub fn deserializeOption(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
    //return visitor.visitOption(value) catch return Error.DeserializationError;
    //}
};

/// Client data structure
const PublishState = enum {
    Published,
    Unpublished,
};

/// Visitor implementation
const PublishStateVisitor = struct {
    const Self = @This();

    const Ok = PublishState;
    const Error = error{VisitorError};

    const V = Visitor(
        *Self,
        Ok,
        Error,
        visitBool,
        visitInt,
    );

    pub fn visitor(self: *Self) V {
        return .{ .context = self };
    }

    fn visitBool(self: *Self, value: bool) Error!Ok {
        return switch (value) {
            true => .Published,
            false => .Unpublished,
        };
    }

    fn visitInt(self: *Self, value: anytype) Error!Ok {
        if (value > 0) {
            return .Published;
        } else {
            return .Unpublished;
        }
    }
};

test "bool" {
    var print_visitor = PublishStateVisitor{};
    const visitor = print_visitor.visitor();

    {
        var test_deserializer = TestDeserializer{ .input = "true" };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeBool(visitor);
        try std.testing.expect(publish_state == .Published);
    }

    {
        var test_deserializer = TestDeserializer{ .input = "false" };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeBool(visitor);
        try std.testing.expect(publish_state == .Unpublished);
    }

    {
        var test_deserializer = TestDeserializer{ .input = "" };
        const deserializer = test_deserializer.deserializer();

        if (deserializer.deserializeBool(visitor)) |_| {
            unreachable;
        } else |err| {
            try std.testing.expect(err == TestDeserializer.Error.DeserializationError);
        }
    }
}

test "int" {
    var print_visitor = PublishStateVisitor{};
    const visitor = print_visitor.visitor();

    {
        var test_deserializer = TestDeserializer{ .input = "0" };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeInt(visitor);
        try std.testing.expect(publish_state == .Unpublished);
    }

    {
        var test_deserializer = TestDeserializer{ .input = "1" };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeInt(visitor);
        try std.testing.expect(publish_state == .Published);
    }

    {
        var test_deserializer = TestDeserializer{ .input = "-1" };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeInt(visitor);
        try std.testing.expect(publish_state == .Unpublished);
    }
}

comptime {
    std.testing.refAllDecls(@This());
}
