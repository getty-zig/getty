const std = @import("std");

const Content = @import("../../content.zig").Content;
const ContentMultiArrayList = @import("../../content.zig").ContentMultiArrayList;
const getty_deserialize = @import("../../deserialize.zig").deserialize;
const getty_free = @import("../../free.zig").free;
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

fn visitBool(_: @This(), _: ?std.mem.Allocator, comptime Deserializer: type, input: bool) Deserializer.Error!Content {
    return .{ .Bool = input };
}

fn visitFloat(_: @This(), _: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Content {
    return switch (@TypeOf(input)) {
        f16 => .{ .F16 = input },
        f32 => .{ .F32 = input },
        f64 => .{ .F64 = input },
        f128 => .{ .F128 = input },
        comptime_float => @compileError("comptime_float is not supported"),
        else => unreachable, // UNREACHABLE: The Visitor interface guarantees that input is a float.
    };
}

fn visitInt(_: @This(), ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Content {
    if (ally == null) {
        return error.MissingAllocator;
    }

    return switch (@typeInfo(@TypeOf(input))) {
        .Int => .{ .Int = try std.math.big.int.Managed.initSet(ally.?, input) },
        .ComptimeInt => @compileError("comptime_int is not supported"),
        else => unreachable, // UNREACHABLE: The Visitor interface guarantees that input is an integer.
    };
}

fn visitMap(_: @This(), ally: ?std.mem.Allocator, comptime Deserializer: type, mapAccess: anytype) Deserializer.Error!Content {
    if (ally == null) {
        return error.MissingAllocator;
    }

    var map = ContentMultiArrayList{};
    errdefer map.deinit(ally.?);

    while (try mapAccess.nextKey(ally.?, Content)) |key| {
        errdefer if (mapAccess.isKeyAllocated(@TypeOf(key))) {
            getty_free(ally.?, Deserializer, key);
        };

        const value = try mapAccess.nextValue(ally, Content);
        errdefer getty_free(ally.?, Deserializer, value);

        try map.append(ally.?, .{
            .key = key,
            .value = value,
        });
    }

    return .{ .Map = map };
}

fn visitNull(_: @This(), _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Content {
    return .{ .Null = {} };
}

fn visitSeq(_: @This(), ally: ?std.mem.Allocator, comptime Deserializer: type, seqAccess: anytype) Deserializer.Error!Content {
    if (ally == null) {
        return error.MissingAllocator;
    }

    var list = std.ArrayList(Content).init(ally.?);
    errdefer list.deinit();

    while (try seqAccess.nextElement(ally.?, Content)) |elem| {
        try list.append(elem);
    }

    return .{ .Seq = list };
}

fn visitSome(_: @This(), ally: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Content {
    return .{ .Some = try getty_deserialize(ally, *Content, deserializer) };
}

fn visitString(_: @This(), ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Content {
    const output = try ally.?.alloc(u8, input.len);
    std.mem.copy(u8, output, input);

    return .{ .String = output };
}

fn visitUnion(_: @This(), ally: ?std.mem.Allocator, comptime Deserializer: type, ua: anytype, va: anytype) Deserializer.Error!Content {
    if (ally == null) {
        return error.MissingAllocator;
    }

    var variant = try ua.variant(ally, Content);
    errdefer if (ua.isVariantAllocated(@TypeOf(variant))) {
        getty_free(ally.?, Deserializer, variant);
    };

    var payload = try va.payload(ally.?, Content);
    errdefer getty_free(ally.?, Deserializer, payload);

    var map = ContentMultiArrayList{};
    errdefer map.deinit(ally.?);

    try map.append(ally.?, .{
        .key = variant,
        .value = payload,
    });

    return .{ .Map = map };
}

fn visitVoid(_: @This(), _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Content {
    return .{ .Void = {} };
}
