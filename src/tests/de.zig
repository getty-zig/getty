const std = @import("std");
const de = @import("getty").de;

const eql = std.mem.eql;

const Deserializer = struct {
    input: []const u8,

    const Self = @This();

    pub const Error = error{DeserializationError};

    /// Implements `getty.de.Deserializer`.
    pub const D = de.Deserializer(
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
        if (eql(u8, self.input, "true")) {
            return visitor.visitBool(true) catch return Error.DeserializationError;
        } else if (eql(u8, self.input, "false")) {
            return visitor.visitBool(false) catch return Error.DeserializationError;
        }

        return Error.DeserializationError;
    }

    /// Implements `intFn` for `getty.de.Deserializer`.
    pub fn deserializeInt(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
        const value = std.json.parse(i64, &std.json.TokenStream.init(self.input), .{}) catch return Error.DeserializationError;
        return visitor.visitInt(value) catch return Error.DeserializationError;
    }
};

const PublishState = enum {
    Published,
    Unpublished,
};

const PublishStateVisitor = struct {
    const Self = @This();

    const Ok = PublishState;
    const Error = error{VisitorError};

    const V = de.Visitor(
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
        var test_deserializer = Deserializer{ .input = "true" };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeBool(visitor);
        try std.testing.expect(publish_state == .Published);
    }

    {
        var test_deserializer = Deserializer{ .input = "false" };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeBool(visitor);
        try std.testing.expect(publish_state == .Unpublished);
    }

    {
        var test_deserializer = Deserializer{ .input = "" };
        const deserializer = test_deserializer.deserializer();

        if (deserializer.deserializeBool(visitor)) |_| {
            unreachable;
        } else |err| {
            try std.testing.expect(err == Deserializer.Error.DeserializationError);
        }
    }
}

test "int" {
    var print_visitor = PublishStateVisitor{};
    const visitor = print_visitor.visitor();

    {
        var test_deserializer = Deserializer{ .input = "0" };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeInt(visitor);
        try std.testing.expect(publish_state == .Unpublished);
    }

    {
        var test_deserializer = Deserializer{ .input = "1" };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeInt(visitor);
        try std.testing.expect(publish_state == .Published);
    }

    {
        var test_deserializer = Deserializer{ .input = "-1" };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeInt(visitor);
        try std.testing.expect(publish_state == .Unpublished);
    }
}
