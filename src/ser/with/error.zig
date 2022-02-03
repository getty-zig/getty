const getty = @import("../../lib.zig");

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .ErrorSet;
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try getty.serialize(@as([]const u8, @errorName(value)), serializer);
}
