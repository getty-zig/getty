const std = @import("std");
const attr = @import("../attribute.zig");

const Serializer = @import("../serialize.zig").Serializer;

pub fn Serialize(comptime T: type, attr_map: anytype) type {
    attr.check_attributes(T, attr_map, .Ser);

    return struct {
        pub fn serialize(self: *T, serializer: Serializer) void {
            switch (@typeInfo(T)) {
                .AnyFrame => {},
                .Array => {},
                .Bool => std.debug.print("try serializer.serialize_bool()\n", .{}),
                .BoundFn => {},
                .ComptimeFloat => {},
                .ComptimeInt => {},
                .Enum => {},
                .EnumLiteral => {},
                .ErrorSet => {},
                .ErrorUnion => {},
                .Float => {},
                .Fn => {},
                .Frame => {},
                .Int => {},
                .NoReturn => {},
                .Null => {},
                .Opaque => {},
                .Optional => {},
                .Pointer => {},
                .Struct => std.debug.print("try serializer.serialize_struct()\n", .{}),
                .Type => {},
                .Undefined => {},
                .Union => {},
                .Vector => {},
                .Void => {},
            }
        }
    };
}

const expect = std.testing.expect;

test "Serialize - basic (struct)" {
    const T = struct {
        usingnamespace Serialize(@This(), .{});

        x: i32,
        y: i32,
    };
}

test "Serialize - with container attribute (struct)" {
    const T = struct {
        usingnamespace Serialize(@This(), .{ .T = .{ .rename = "A" } });

        x: i32,
        y: i32,
    };
}

test "Serialize - with field attribute (struct)" {
    const T = struct {
        usingnamespace Serialize(@This(), .{ .x = .{ .rename = "a" } });

        x: i32,
        y: i32,
    };
}

comptime {
    std.testing.refAllDecls(@This());
}
