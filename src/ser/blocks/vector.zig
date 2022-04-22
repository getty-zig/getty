const getty = @import("../../lib.zig");

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Vector;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const info = @typeInfo(@TypeOf(value)).Vector;

    return try getty.serialize(@as([info.len]info.child, value), serializer);
}
