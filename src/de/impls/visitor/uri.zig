const std = @import("std");

const StringLifetime = @import("../../lifetime.zig").StringLifetime;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;
const VisitStringReturn = @import("../../interfaces/visitor.zig").VisitStringReturn;

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
) Deserializer.Err!VisitStringReturn(Value) {
    var uri = std.Uri.parse(input) catch return error.InvalidValue;

    var used = false;
    switch (lt) {
        .heap => used = true,
        .stack, .managed => {
            uri.scheme = try ally.dupe(u8, uri.scheme);

            if (uri.user) |user| {
                uri.user = switch (user) {
                    .raw => |v| std.Uri.Component{
                        .raw = try ally.dupe(u8, v),
                    },
                    .percent_encoded => |v| std.Uri.Component{
                        .percent_encoded = try ally.dupe(u8, v),
                    },
                };
            }

            if (uri.password) |password| {
                uri.password = switch (password) {
                    .raw => |v| std.Uri.Component{
                        .raw = try ally.dupe(u8, v),
                    },
                    .percent_encoded => |v| std.Uri.Component{
                        .percent_encoded = try ally.dupe(u8, v),
                    },
                };
            }

            if (uri.host) |host| {
                uri.host = switch (host) {
                    .raw => |v| std.Uri.Component{
                        .raw = try ally.dupe(u8, v),
                    },
                    .percent_encoded => |v| std.Uri.Component{
                        .percent_encoded = try ally.dupe(u8, v),
                    },
                };
            }

            uri.path = switch (uri.path) {
                .raw => |v| std.Uri.Component{
                    .raw = try ally.dupe(u8, v),
                },
                .percent_encoded => |v| std.Uri.Component{
                    .percent_encoded = try ally.dupe(u8, v),
                },
            };

            if (uri.query) |query| {
                uri.query = switch (query) {
                    .raw => |v| std.Uri.Component{
                        .raw = try ally.dupe(u8, v),
                    },
                    .percent_encoded => |v| std.Uri.Component{
                        .percent_encoded = try ally.dupe(u8, v),
                    },
                };
            }

            if (uri.fragment) |fragment| {
                uri.fragment = switch (fragment) {
                    .raw => |v| std.Uri.Component{
                        .raw = try ally.dupe(u8, v),
                    },
                    .percent_encoded => |v| std.Uri.Component{
                        .percent_encoded = try ally.dupe(u8, v),
                    },
                };
            }
        },
    }

    return .{ .value = uri, .used = used };
}
