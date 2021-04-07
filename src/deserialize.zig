const std = @import("std");

const Deserialize = struct {
    const Self = @This();
    const Error = error{};

    const Address = usize;
    //const VTable = struct { deserialize: fn (Address, Deserializer) Error!void };
    const VTable = struct { deserialize: fn (Address) Error!void };

    vtable: *const VTable,
    object: Address,

    //fn deserialize(self: Self, deserializer: Deserializer) Error!void {
    fn deserialize(self: Self) Error!void {
        //self.vtable.deserialize(self.object, deserializer);
        try self.vtable.deserialize(self.object);
    }

    fn init(obj: anytype) Self {
        const Pointer = @TypeOf(obj);

        const deserialize_fn = struct {
            //fn deserialize(address: Address, deserializer: Deserializer) Error!void {
            fn deserialize(address: Address) Error!void {
                @call(
                    .{ .modifier = .always_inline },
                    std.meta.Child(Pointer).deserialize,
                    //.{ @intToPtr(Pointer, address), deserializer },
                    .{@intToPtr(Pointer, address)},
                );
            }
        }.deserialize;

        return .{
            .vtable = &comptime VTable{ .deserialize = deserialize_fn },
            .object = @ptrToInt(obj),
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
