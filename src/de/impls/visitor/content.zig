const std = @import("std");

const Content = @import("../../content.zig").Content;
const ContentMultiArrayList = @import("../../content.zig").ContentMultiArrayList;
const getty_deserialize = @import("../../deserialize.zig").deserialize;
const StringLifetime = @import("../../lifetime.zig").StringLifetime;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

const Visitor = @This();

pub usingnamespace VisitorInterface(
    @This(),
    Value,
    .{
        .visitBool = visitBool,
        .visitFloat = visitFloat,
        .visitInt = visitInt,
        .visitMap = visitMap,
        .visitNull = visitNull,
        .visitSeq = visitSeq,
        .visitSome = visitSome,
        .visitString = visitString,
        .visitUnion = visitUnion,
        .visitVoid = visitVoid,
    },
);

const Value = Content;

fn visitBool(_: @This(), _: std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Err!Content {
    return .{ .Bool = input };
}

fn visitFloat(_: @This(), _: std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Err!Content {
    return switch (@TypeOf(input)) {
        f16 => .{ .F16 = input },
        f32 => .{ .F32 = input },
        f64 => .{ .F64 = input },
        f128 => .{ .F128 = input },
        comptime_float => @compileError("comptime_float is not supported"),
        else => unreachable, // UNREACHABLE: The Visitor interface guarantees that input is a float.
    };
}

fn visitInt(_: @This(), ally: std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Err!Content {
    return switch (@typeInfo(@TypeOf(input))) {
        .Int => .{ .Int = try std.math.big.int.Managed.initSet(ally, input) },
        .ComptimeInt => @compileError("comptime_int is not supported"),
        else => unreachable, // UNREACHABLE: The Visitor interface guarantees that input is an integer.
    };
}

fn visitMap(_: @This(), ally: std.mem.Allocator, comptime Deserializer: type, mapAccess: anytype) Deserializer.Err!Content {
    var map = ContentMultiArrayList{};
    errdefer map.deinit(ally);

    while (try mapAccess.nextKey(ally, Content)) |key| {
        const value = try mapAccess.nextValue(ally, Content);

        try map.append(ally, .{
            .key = key,
            .value = value,
        });
    }

    return .{ .Map = map };
}

fn visitNull(_: @This(), _: std.mem.Allocator, comptime Deserializer: type) Deserializer.Err!Content {
    return .{ .Null = {} };
}

fn visitSeq(_: @This(), ally: std.mem.Allocator, comptime Deserializer: type, seqAccess: anytype) Deserializer.Err!Content {
    var list = std.ArrayList(Content).init(ally);
    errdefer list.deinit();

    while (try seqAccess.nextElement(ally, Content)) |elem| {
        try list.append(elem);
    }

    return .{ .Seq = list };
}

fn visitSome(_: @This(), ally: std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Err!Content {
    return .{ .Some = some: {
        var result = try getty_deserialize(ally, *Content, deserializer);
        break :some result.value;
    } };
}

fn visitString(
    _: @This(),
    ally: std.mem.Allocator,
    comptime Deserializer: type,
    input: anytype,
    lt: StringLifetime,
) Deserializer.Err!Content {
    switch (lt) {
        .heap => return .{ .String = @as([]const u8, input) },
        .stack, .owned => {
            const copy = try ally.alloc(u8, input.len);
            std.mem.copy(u8, copy, input);
            return .{ .String = copy };
        },
    }
}

fn visitUnion(_: @This(), ally: std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Err!Content {
    var variant = try ua.variant(ally, Content);
    var payload = try va.payload(ally, Content);

    var map = ContentMultiArrayList{};
    errdefer map.deinit(ally);

    try map.append(ally, .{
        .key = variant,
        .value = payload,
    });

    return .{ .Map = map };
}

fn visitVoid(_: @This(), _: std.mem.Allocator, comptime Deserializer: type) Deserializer.Err!Content {
    return .{ .Void = {} };
}
