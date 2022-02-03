const getty = @import("../../lib.zig");
const std = @import("std");

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Union;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    switch (@typeInfo(@TypeOf(value))) {
        .Union => |info| if (info.tag_type) |_| {
            inline for (info.fields) |field| {
                if (std.mem.eql(u8, field.name, @tagName(value))) {
                    return try getty.serialize(@field(value, field.name), serializer);
                }
            }
        } else @compileError("expected tagged union, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
        else => @compileError("expected tagged union, found `" ++ @typeName(@TypeOf(value)) ++ "`"),
    }
}
