const std = @import("std");

const de = @import("../../de.zig").de;

/// A `getty.de.Seed` implementation that ignores values.
pub const Ignored = struct {
    const Value = Ignored;

    ////////////////////////////////////////////////////////////////////////////
    // Seed
    ////////////////////////////////////////////////////////////////////////////

    pub usingnamespace de.Seed(
        Ignored,
        Value,
        .{ .deserialize = deserialize },
    );

    fn deserialize(i: Value, allocator: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
        return try deserializer.deserializeIgnored(allocator, i.visitor());
    }

    ////////////////////////////////////////////////////////////////////////////
    // Visitor
    ////////////////////////////////////////////////////////////////////////////

    pub usingnamespace de.Visitor(
        Ignored,
        Value,
        .{
            .visitBool = visitBool,
            .visitEnum = visitAny,
            .visitFloat = visitAny,
            .visitInt = visitAny,
            .visitMap = visitAny,
            .visitNull = visitNothing,
            .visitSeq = visitAny,
            .visitSome = visitSome,
            .visitString = visitAny,
            .visitUnion = visitUnion,
            .visitVoid = visitNothing,
        },
    );

    fn visitBool(_: Ignored, _: ?std.mem.Allocator, comptime Deserializer: type, _: bool) Deserializer.Error!Value {
        return .{};
    }

    fn visitAny(_: Ignored, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype) Deserializer.Error!Value {
        return .{};
    }
    fn visitSome(_: Ignored, _: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
        return .{};
    }

    fn visitUnion(_: Ignored, _: ?std.mem.Allocator, comptime Deserializer: type, _: anytype, _: anytype) Deserializer.Error!Value {
        return .{};
    }

    fn visitNothing(_: Ignored, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
        return .{};
    }
};
