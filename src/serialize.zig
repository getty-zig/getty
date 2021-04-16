const std = @import("std");

pub const Serialize = struct {
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

const TestPoint = struct {
    x: i32,
    y: i32,

    fn serialize(self: *@This(), serializer: Serializer) void {
        std.log.warn("Serialize", .{});
    }
};

const TestSerializer = struct {
    // FIXME: Serializer with no state gives a poitner of size 0, making Serializer.init() fail.
    v: bool,

    fn serialize_bool(self: *@This(), v: bool) void {
        std.log.warn("Serializer", .{});
    }
};

test "Serialize - init" {
    var p = TestPoint{ .x = 1, .y = 2 };
    var s = TestSerializer{ .v = true };

    var serialize = Serialize.init(&p);
    var serializer = Serializer.init(&s);

    try serialize.serialize(serializer);
    try serializer.serialize_bool(true);
}

comptime {
    std.testing.refAllDecls(@This());
}
