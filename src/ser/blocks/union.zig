const std = @import("std");
const t = @import("getty/testing");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Union;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);
    const info = @typeInfo(T).Union;

    if (info.tag_type == null) {
        @compileError(std.fmt.comptimePrint("type `{s} is not supported", .{@typeName(T)}));
    }

    var m = try serializer.serializeMap(1);
    const map = m.map();
    inline for (info.fields) |field| {
        if (std.mem.eql(u8, field.name, @tagName(value))) {
            try map.serializeEntry(field.name, @field(value, field.name));
        }
    }
    return try map.end();
}

test "serialize - union" {
    const Union = union(enum) { Int: i32, Bool: bool };

    try t.ser.run(serialize, Union{ .Int = 0 }, &[_]t.Token{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Int" },
        .{ .I32 = 0 },
        .{ .MapEnd = {} },
    });
    try t.ser.run(serialize, Union{ .Bool = true }, &[_]t.Token{
        .{ .Map = .{ .len = 1 } },
        .{ .String = "Bool" },
        .{ .Bool = true },
        .{ .MapEnd = {} },
    });
}
