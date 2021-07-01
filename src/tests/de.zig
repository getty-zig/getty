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
        deserializeAny,
        deserializeBool,
        deserializeInt,
        deserializeFloat,
        deserializeOption,
        deserializeSequence,
        deserializeString,
        deserializeStruct,
        deserializeVariant,
    );

    pub fn deserializer(self: *Self) D {
        return .{ .context = self };
    }

    /// Implements `anyFn` for `getty.de.Deserializer`.
    pub fn deserializeAny(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
        _ = self;
        _ = visitor;

        @compileError("TODO: any");
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
    ///
    /// TODO: Update self.input
    pub fn deserializeInt(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
        const value = std.json.parse(i64, &std.json.TokenStream.init(self.input), .{}) catch return Error.DeserializationError;
        return visitor.visitInt(value) catch return Error.DeserializationError;
    }

    /// Implements `floatFn` for `getty.de.Deserializer`.
    ///
    /// Float parsing is hard.
    pub fn deserializeFloat(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
        _ = self;
        _ = visitor;

        @compileError("Unimplemented: float");
    }

    /// Implements `optionFn` for `getty.de.Deserializer`.
    pub fn deserializeOption(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
        _ = self;
        _ = visitor;

        @compileError("TODO: option");

        //if (std.mem.startsWith(u8, self.input, "null")) {
        //self.input = self.input["null".len..];
        //return visitor.visitNull();
        //}

        //return visitor.visitSome();
    }

    /// Implements `sequenceFn` for `getty.de.Deserializer`.
    pub fn deserializeSequence(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
        _ = self;
        _ = visitor;

        @compileError("TODO: sequence");
    }

    /// Implements `stringFn` for `getty.de.Deserializer`.
    pub fn deserializeString(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
        _ = self;
        _ = visitor;

        @compileError("TODO: string");
    }

    /// Implements `structFn` for `getty.de.Deserializer`.
    pub fn deserializeStruct(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
        _ = self;
        _ = visitor;

        @compileError("TODO: struct");
    }

    /// Implements `variantFn` for `getty.de.Deserializer`.
    pub fn deserializeVariant(self: *Self, visitor: anytype) Error!@TypeOf(visitor).Ok {
        _ = self;
        _ = visitor;

        @compileError("TODO: variant");
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

    /// Implements `getty.de.Visitor`.
    const V = de.Visitor(
        *Self,
        Ok,
        Error,
        visitBool,
        visitInt,
        visitFloat,
        visitNull,
        visitSome,
        visitSequence,
        visitString,
        visitStruct,
        visitVariant,
    );

    pub fn visitor(self: *Self) V {
        return .{ .context = self };
    }

    /// Implements `boolFn` for `getty.de.Visitor`.
    fn visitBool(_: *Self, value: bool) Error!Ok {
        return switch (value) {
            true => .Published,
            false => .Unpublished,
        };
    }

    /// Implements `intFn` for `getty.de.Visitor`.
    fn visitInt(_: *Self, value: anytype) Error!Ok {
        if (value > 0) {
            return .Published;
        } else {
            return .Unpublished;
        }
    }

    /// Implements `floatFn` for `getty.de.Visitor`.
    pub fn visitFloat(_: *Self, value: anytype) Error!Ok {
        if (value > 0.0) {
            return .Published;
        } else {
            return .Unpublished;
        }
    }

    /// Implements `nullFn` for `getty.de.Visitor`.
    pub fn visitNull(_: *Self) Error!Ok {
        return .Unpublished;
    }

    /// Implements `someFn` for `getty.de.Visitor`.
    pub fn visitSome(_: *Self, value: anytype) Error!Ok {
        _ = value;

        return .Published;
    }

    /// Implements `sequenceFn` for `getty.de.Visitor`.
    pub fn visitSequence(self: *Self, value: anytype) Error!Ok {
        _ = self;
        _ = value;

        @compileError("TODO: sequence");
    }

    /// Implements `stringFn` for `getty.de.Visitor`.
    pub fn visitString(self: *Self, value: anytype) Error!Ok {
        _ = self;
        _ = value;

        @compileError("TODO: string");
    }

    /// Implements `structFn` for `getty.de.Visitor`.
    pub fn visitStruct(self: *Self, value: anytype) Error!Ok {
        _ = self;
        _ = value;

        @compileError("TODO: struct");
    }

    /// Implements `variantFn` for `getty.de.Visitor`.
    pub fn visitVariant(self: *Self, value: anytype) Error!Ok {
        _ = self;
        _ = value;

        @compileError("TODO: variant");
    }
};

test "bool" {
    var print_visitor = PublishStateVisitor{};
    const visitor = print_visitor.visitor();

    {
        const test_cases = [_]struct { input: []const u8, output: PublishState }{
            .{ .input = "true", .output = .Published },
            .{ .input = "false", .output = .Unpublished },
        };

        for (test_cases) |t| {
            var test_deserializer = Deserializer{ .input = t.input };
            const deserializer = test_deserializer.deserializer();

            var state = try deserializer.deserializeBool(visitor);
            try std.testing.expect(state == t.output);
        }
    }

    {
        const test_cases = [_]struct { input: []const u8, output: Deserializer.Error }{
            .{ .input = "", .output = error.DeserializationError },
            .{ .input = "foo", .output = error.DeserializationError },
        };

        for (test_cases) |t| {
            var test_deserializer = Deserializer{ .input = t.input };
            const deserializer = test_deserializer.deserializer();

            if (deserializer.deserializeBool(visitor)) |_| {
                unreachable;
            } else |err| {
                try std.testing.expect(err == t.output);
            }
        }
    }
}

test "int" {
    var print_visitor = PublishStateVisitor{};
    const visitor = print_visitor.visitor();

    const test_cases = [_]struct { input: []const u8, output: PublishState }{
        .{ .input = "0", .output = .Unpublished },
        .{ .input = "1", .output = .Published },
        .{ .input = "-1", .output = .Unpublished },
    };

    for (test_cases) |t| {
        var test_deserializer = Deserializer{ .input = t.input };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeInt(visitor);
        try std.testing.expect(publish_state == t.output);
    }
}

test "float" {
    var print_visitor = PublishStateVisitor{};
    const visitor = print_visitor.visitor();

    const test_cases = [_]struct { input: []const u8, output: PublishState }{
        .{ .input = "0.0", .output = .Unpublished },
        .{ .input = "1.0", .output = .Published },
        .{ .input = "-1.0", .output = .Unpublished },
        .{ .input = "3.1415", .output = .Published },
    };

    for (test_cases) |t| {
        var test_deserializer = Deserializer{ .input = t.input };
        const deserializer = test_deserializer.deserializer();

        var publish_state = try deserializer.deserializeFloat(visitor);
        try std.testing.expect(publish_state == t.output);
    }
}
