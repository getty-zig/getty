const std = @import("std");

const Serialize = struct {
    const Address = usize;
    const Error = error{};
    const VTable = struct { serialize: fn (Address, Serializer) Error!void };

    object: Address,
    vtable: *const VTable,

    fn init(obj: anytype) @This() {
        const Pointer = @TypeOf(obj);

        const serialize_fn = struct {
            fn serialize(address: Address, serializer: Serializer) Error!void {
                @call(.{ .modifier = .always_inline }, std.meta.Child(Pointer).serialize, .{ @intToPtr(Pointer, address), serializer });
            }
        }.serialize;

        return .{
            .object = @ptrToInt(obj),
            .vtable = &comptime VTable{ .serialize = serialize_fn },
        };
    }

    fn serialize(self: @This(), serializer: Serializer) Error!void {
        try self.vtable.serialize(self.object, serializer);
    }
};

pub const Serializer = struct {
    const Address = usize;
    const Error = error{};
    const VTable = struct {
        serialize_bool: fn (Address, bool) Error!void
    };

    object: Address,
    vtable: *const VTable,

    fn init(obj: anytype) @This() {
        const Pointer = @TypeOf(obj);

        const serialize_bool_fn = struct {
            fn serialize_bool(address: Address, v: bool) Error!void {
                @call(.{ .modifier = .always_inline }, std.meta.Child(Pointer).serialize_bool, .{ @intToPtr(Pointer, address), v });
            }
        }.serialize_bool;

        return .{
            .object = @ptrToInt(obj),
            .vtable = &comptime VTable{ .serialize_bool = serialize_bool_fn },
        };
    }

    pub fn serialize_bool(self: @This(), v: bool) Error!void {
        try self.vtable.serialize_bool(self.object, v);
    }
};

const derive = @import("derive/serialize.zig");

test "Serialize - init" {
    const Point = struct {
        usingnamespace derive.Serialize(@This(), .{});

        x: i32,
        y: i32,
    };

    const Ser = struct {
        v: bool,

        fn serialize_bool(self: *@This(), v: bool) void {
            std.log.warn("serialize_bool\n", .{});
        }
    };

    var point = Point{ .x = 1, .y = 2 };
    var ser = Ser{ .v = true };

    var s = Serialize.init(&point);
    var serializer = Serializer.init(&ser);

    try s.serialize(serializer);
}
