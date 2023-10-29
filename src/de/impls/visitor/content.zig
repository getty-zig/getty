const std = @import("std");

const Content = @import("../../content.zig").Content;
const ContentMultiArrayList = @import("../../content.zig").ContentMultiArrayList;
const getty_deserialize = @import("../../deserialize.zig").deserialize;
const StringLifetime = @import("../../lifetime.zig").StringLifetime;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;
const VisitStringReturn = @import("../../interfaces/visitor.zig").VisitStringReturn;

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

fn visitBool(
    _: @This(),
    result_ally: std.mem.Allocator,
    scratch_ally: std.mem.Allocator,
    comptime Deserializer: type,
    input: bool,
) Deserializer.Err!Content {
    _ = result_ally;
    _ = scratch_ally;

    return .{ .Bool = input };
}

fn visitFloat(
    _: @This(),
    result_ally: std.mem.Allocator,
    scratch_ally: std.mem.Allocator,
    comptime Deserializer: type,
    input: anytype,
) Deserializer.Err!Content {
    _ = result_ally;
    _ = scratch_ally;

    return switch (@TypeOf(input)) {
        f16 => .{ .F16 = input },
        f32 => .{ .F32 = input },
        f64 => .{ .F64 = input },
        f128 => .{ .F128 = input },
        comptime_float => @compileError("comptime_float is not supported"),
        else => unreachable, // UNREACHABLE: The Visitor interface guarantees that input is a float.
    };
}

fn visitInt(
    _: @This(),
    result_ally: std.mem.Allocator,
    scratch_ally: std.mem.Allocator,
    comptime Deserializer: type,
    input: anytype,
) Deserializer.Err!Content {
    _ = scratch_ally;

    return switch (@typeInfo(@TypeOf(input))) {
        .Int => .{ .Int = try std.math.big.int.Managed.initSet(result_ally, input) },
        .ComptimeInt => @compileError("comptime_int is not supported"),
        else => unreachable, // UNREACHABLE: The Visitor interface guarantees that input is an integer.
    };
}

fn visitMap(
    _: @This(),
    result_ally: std.mem.Allocator,
    scratch_ally: std.mem.Allocator,
    comptime Deserializer: type,
    mapAccess: anytype,
) Deserializer.Err!Content {
    _ = scratch_ally;

    var map = ContentMultiArrayList{};
    errdefer map.deinit(result_ally);

    while (try mapAccess.nextKey(result_ally, Content)) |key| {
        const value = try mapAccess.nextValue(result_ally, Content);

        try map.append(result_ally, .{
            .key = key,
            .value = value,
        });
    }

    return .{ .Map = map };
}

fn visitNull(
    _: @This(),
    result_ally: std.mem.Allocator,
    scratch_ally: std.mem.Allocator,
    comptime Deserializer: type,
) Deserializer.Err!Content {
    _ = result_ally;
    _ = scratch_ally;

    return .{ .Null = {} };
}

fn visitSeq(
    _: @This(),
    result_ally: std.mem.Allocator,
    scratch_ally: std.mem.Allocator,
    comptime Deserializer: type,
    seqAccess: anytype,
) Deserializer.Err!Content {
    _ = scratch_ally;

    var list = std.ArrayList(Content).init(result_ally);
    errdefer list.deinit();

    while (try seqAccess.nextElement(result_ally, Content)) |elem| {
        try list.append(elem);
    }

    return .{ .Seq = list };
}

fn visitSome(
    _: @This(),
    result_ally: std.mem.Allocator,
    scratch_ally: std.mem.Allocator,
    deserializer: anytype,
) @TypeOf(deserializer).Err!Content {
    _ = scratch_ally;

    return .{ .Some = some: {
        var result = try getty_deserialize(result_ally, *Content, deserializer);
        break :some result.value;
    } };
}

fn visitString(
    _: @This(),
    result_ally: std.mem.Allocator,
    scratch_ally: std.mem.Allocator,
    comptime Deserializer: type,
    input: anytype,
    lt: StringLifetime,
) Deserializer.Err!VisitStringReturn(Content) {
    _ = scratch_ally;

    switch (lt) {
        .heap => return .{
            .value = .{ .String = @as([]const u8, input) },
            .used = true,
        },
        .stack, .managed => {
            const copy = try result_ally.alloc(u8, input.len);
            std.mem.copy(u8, copy, input);
            return .{ .value = .{ .String = copy }, .used = false };
        },
    }
}

fn visitUnion(
    _: @This(),
    result_ally: std.mem.Allocator,
    scratch_ally: std.mem.Allocator,
    comptime Deserializer: type,
    ua: anytype,
    va: anytype,
) Deserializer.Err!Content {
    _ = scratch_ally;

    var variant = try ua.variant(result_ally, Content);
    var payload = try va.payload(result_ally, Content);

    var map = ContentMultiArrayList{};
    errdefer map.deinit(result_ally);

    try map.append(result_ally, .{
        .key = variant,
        .value = payload,
    });

    return .{ .Map = map };
}

fn visitVoid(
    _: @This(),
    result_ally: std.mem.Allocator,
    scratch_ally: std.mem.Allocator,
    comptime Deserializer: type,
) Deserializer.Err!Content {
    _ = result_ally;
    _ = scratch_ally;

    return .{ .Void = {} };
}
