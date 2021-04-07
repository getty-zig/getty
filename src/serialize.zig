const std = @import("std");

const Serialize = struct {
    const Self = @This();
    const Error = error{};

    const Address = usize;
    //const VTable = struct { serialize: fn (Address, Serializer) Error!void };
    const VTable = struct { serialize: fn (Address) Error!void };

    vtable: *const VTable,
    object: Address,

    //fn serialize(self: Self, serializer: Serializer) Error!void {
    fn serialize(self: Self) Error!void {
        //self.vtable.serialize(self.object, serializer);
        try self.vtable.serialize(self.object);
    }

    fn init(obj: anytype) Self {
        const Pointer = @TypeOf(obj);

        const serialize_fn = struct {
            //fn serialize(address: Address, serializer: Serializer) Error!void {
            fn serialize(address: Address) Error!void {
                @call(
                    .{ .modifier = .always_inline },
                    std.meta.Child(Pointer).serialize,
                    //.{ @intToPtr(Pointer, address), serializer },
                    .{@intToPtr(Pointer, address)},
                );
            }
        }.serialize;

        return .{
            .vtable = &comptime VTable{ .serialize = serialize_fn },
            .object = @ptrToInt(obj),
        };
    }
};

const derive = @import("derive/serialize.zig");

test "Serialize - init" {
    const Point = struct {
        usingnamespace derive.Serialize(@This(), .{});

        x: i32,
        y: i32,
    };

    var point = Point{ .x = 1, .y = 2 };
    try Serialize.init(&point).serialize();
}
