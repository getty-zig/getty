const std = @import("std");

fn DeserializerFn(comptime Context: type, comptime Error: type) type {
    return @TypeOf(struct {
        fn f(context: Context, visitor: anytype) Error!std.meta.Child(@TypeOf(visitor)).Ok {
            unreachable;
        }
    }.f);
}

/// An interface for deserializing input into Getty's data model.
pub fn Deserializer(
    comptime Context: type,
    comptime E: type,
    comptime deserializeBoolFn: DeserializerFn(Context, E),
) type {
    return struct {
        context: Context,

        const Self = @This();

        pub const Error = E;

        pub fn deserializeBool(self: *Self, visitor: anytype) E!std.meta.Child(@TypeOf(visitor)).Ok {
            return try deserializeBoolFn(self.context, visitor);
        }
    };
}

/// An interface for deserializing Getty data types into higher-level,
/// user-defined types.
pub fn Visitor(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime visitBoolFn: fn (Context, bool) E!O,
) type {
    return struct {
        context: Context,

        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        pub fn visitBool(self: *Self, value: bool) E!O {
            return try visitBoolFn(self.context, value);
        }
    };
}

/// Visitable implementation
const TestDeserializer = struct {
    input: []const u8,

    const Self = @This();

    const Error = error{DeserializationError};

    const D = Deserializer(
        *Self,
        Error,
        deserializeBool,
    );

    pub fn deserializer(self: *Self) D {
        return .{ .context = self };
    }

    pub fn deserializeBool(self: *Self, visitor: anytype) Error!std.meta.Child(@TypeOf(visitor)).Ok {
        return visitor.visitBool(true) catch return Error.DeserializationError;
    }
};

/// Client data structure
const PublishState = enum {
    Published,
    Unpublished,
    Pending,
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
};

test {
    var test_deserializer = TestDeserializer{ .input = "hello" };
    var deserializer = test_deserializer.deserializer();

    var print_visitor = PublishStateVisitor{};
    const visitor = &print_visitor.visitor();

    var publish_state = try deserializer.deserializeBool(visitor);
}

comptime {
    std.testing.refAllDecls(@This());
}
