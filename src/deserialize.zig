const std = @import("std");

const Deserialize = struct {
    const Address = usize;
    const Error = error{};
    const VTable = struct { deserialize: fn (Address, Deserializer) Error!void };

    object: Address,
    vtable: *const VTable,

    fn init(obj: anytype) @This() {
        const Pointer = @TypeOf(obj);

        const deserialize_fn = struct {
            fn deserialize(address: Address, deserializer: Deserializer) Error!void {
                @call(.{ .modifier = .always_inline }, std.meta.Child(Pointer).deserialize, .{ @intToPtr(Pointer, address), deserializer });
            }
        }.deserialize;

        return .{
            .object = @ptrToInt(obj),
            .vtable = &comptime VTable{ .deserialize = deserialize_fn },
        };
    }

    fn deserialize(self: @This(), deserializer: Deserializer) Error!void {
        try self.vtable.deserialize(self.object, deserializer);
    }
};

pub const Deserializer = struct {
    const Address = usize;
    const VTable = struct {};

    vtable: *const VTable,
    object: Address,

    fn init(obj: anytype) @This() {
        const Pointer = @TypeOf(obj);

        return .{
            .object = @ptrToInt(obj),
            .vtable = &comptime VTable{},
        };
    }
};

const derive = @import("derive/deserialize.zig");

test "Deserialize - init" {
    const Point = struct {
        usingnamespace derive.Deserialize(@This(), .{});

        x: i32,
        y: i32,
    };
}
