const getty = @import("../../../lib.zig");

const ErrorVisitor = @This();

pub usingnamespace getty.ser.Visitor(
    *ErrorVisitor,
    serialize,
);

fn serialize(_: *ErrorVisitor, value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    return try getty.serialize(@as([]const u8, @errorName(value)), serializer);
}
