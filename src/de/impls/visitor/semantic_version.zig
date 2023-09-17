const std = @import("std");

const free = @import("../../free.zig").free;
const Range = @import("../../interfaces/visitor.zig").Range;
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

const Value = std.SemanticVersion;

fn visitString(
    _: Visitor,
    ally: ?std.mem.Allocator,
    comptime Deserializer: type,
    input: anytype,
    lifetime: StringLifetime,
) Deserializer.Err!VisitStringReturn(Value) {
    const heap_lt = lifetime == .heap;

    if (!heap_lt and ally == null) {
        return error.MissingAllocator;
    }

    var ver = std.SemanticVersion.parse(input) catch return error.InvalidValue;
    errdefer if (!heap_lt) free(ally.?, Deserializer, ver);

    if (ver.pre == null and ver.build == null) {
        return .{ .value = ver };
    }

    if (ver.pre) |pre| {
        ver.pre = if (heap_lt) pre else try ally.?.dupe(u8, pre);
    }
    if (ver.build) |build| {
        ver.build = if (heap_lt) build else try ally.?.dupe(u8, build);
    }

    if (!heap_lt) {
        return .{ .value = ver };
    }

    // This will always be safe to unwrap since we've already checked that
    // either a pre or build value exists within the semver value.
    const extra_idx = std.mem.indexOfAny(u8, input, "-+").?;
    const extra = input[extra_idx.?..input.len];

    var build_start: usize = undefined;
    var build_end: usize = undefined;

    if (extra[0] == '-') {
        // There is a pre value.
        var pre_start: usize = undefined;
        var pre_end: usize = undefined;

        const build_idx = std.mem.indexOfScalar(u8, extra, '+');
        pre_start = extra_idx.? + 1;
        pre_end = if (build_idx != null) extra_idx + build_idx else extra.len;

        if (build_idx) |idx| {
            // There is a build value.
            build_start = extra_idx.? + idx + 1;
            build_end = input.len;
        } else {
            // There is no build value, so we can return early.
            return .{
                .value = ver,
                .used = .{ .one = .{ .start = pre_start, .end = pre_end } },
            };
        }

        if (ally == null) {
            return error.MissingAllocator;
        }

        // Process pre and build values.
        var used = used: {
            var used = try ally.?.alloc([]const Range, 2);
            used[0] = .{ .start = pre_start, .end = pre_end };
            used[1] = .{ .start = build_start, .end = build_end };
            break :used used;
        };

        return .{
            .value = ver,
            .used = .{ .many = used },
        };
    }

    // There is only a build value.
    build_start = extra_idx.? + 1;
    build_end = input.len;

    return .{
        .value = ver,
        .used = .{ .one = .{ .start = build_start, .end = build_end } },
    };
}
