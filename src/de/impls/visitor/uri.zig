const std = @import("std");

const free = @import("../../free.zig").free;
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

fn visitString(_: Visitor, ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
    if (ally == null) {
        return error.MissingAllocator;
    }

    const a = ally.?;

    var uri = std.Uri.parse(input) catch return error.InvalidValue;
    errdefer free(a, Deserializer, uri);

    uri.scheme = try a.dupe(u8, uri.scheme);
    uri.path = try a.dupe(u8, uri.path);

    if (uri.host) |host| {
        uri.host = try a.dupe(u8, host);
    }
    if (uri.user) |user| {
        uri.user = try a.dupe(u8, user);
    }
    if (uri.password) |password| {
        uri.password = try a.dupe(u8, password);
    }
    if (uri.query) |query| {
        uri.query = try a.dupe(u8, query);
    }
    if (uri.fragment) |fragment| {
        uri.fragment = try a.dupe(u8, fragment);
    }

    return uri;
}
