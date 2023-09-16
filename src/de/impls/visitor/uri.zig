const std = @import("std");

const free = @import("../../free.zig").free;
const StringLifetime = @import("../../lifetime.zig").StringLifetime;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

const Visitor = @This();

pub usingnamespace VisitorInterface(
    Visitor,
    Value,
    .{
        .visitString = visitString,
    },
);

const Value = std.Uri;

fn visitString(
    _: Visitor,
    ally: ?std.mem.Allocator,
    comptime Deserializer: type,
    input: anytype,
    lifetime: StringLifetime,
) Deserializer.Err!Value {
    const heap_lt = lifetime == .heap;

    if (!heap_lt and ally == null) {
        return error.MissingAllocator;
    }

    var uri = std.Uri.parse(input) catch return error.InvalidValue;
    errdefer if (!heap_lt) free(ally.?, Deserializer, uri);

    uri.scheme = if (heap_lt) uri.scheme else try ally.?.dupe(u8, uri.scheme);
    uri.path = if (heap_lt) uri.path else try ally.?.dupe(u8, uri.path);

    if (uri.host) |host| {
        uri.host = if (heap_lt) host else try ally.?.dupe(u8, host);
    }
    if (uri.user) |user| {
        uri.user = if (heap_lt) user else try ally.?.dupe(u8, user);
    }
    if (uri.password) |password| {
        uri.password = if (heap_lt) password else try ally.?.dupe(u8, password);
    }
    if (uri.query) |query| {
        uri.query = if (heap_lt) query else try ally.?.dupe(u8, query);
    }
    if (uri.fragment) |fragment| {
        uri.fragment = if (heap_lt) fragment else try ally.?.dupe(u8, fragment);
    }

    return uri;
}
