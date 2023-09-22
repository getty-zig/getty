const std = @import("std");

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
    ally: std.mem.Allocator,
    comptime Deserializer: type,
    input: anytype,
    lt: StringLifetime,
) Deserializer.Err!Value {
    var uri = std.Uri.parse(input) catch return error.InvalidValue;

    switch (lt) {
        .heap => {},
        .stack, .owned => {
            uri.scheme = try ally.dupe(u8, uri.scheme);
            uri.path = try ally.dupe(u8, uri.path);

            if (uri.host) |host| {
                uri.host = try ally.dupe(u8, host);
            }
            if (uri.user) |user| {
                uri.user = try ally.dupe(u8, user);
            }
            if (uri.password) |password| {
                uri.password = try ally.dupe(u8, password);
            }
            if (uri.query) |query| {
                uri.query = try ally.dupe(u8, query);
            }
            if (uri.fragment) |fragment| {
                uri.fragment = try ally.dupe(u8, fragment);
            }
        },
    }

    return uri;
}
