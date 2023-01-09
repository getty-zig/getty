const std = @import("std");
const t = @import("getty/testing");

const ser = @import("../../ser.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Struct and !@typeInfo(T).Struct.is_tuple;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);
    const fields = std.meta.fields(T);
    const attributes = comptime ser.ser.getAttributes(T, @TypeOf(serializer));

    var s = try serializer.serializeStruct(@typeName(T), fields.len);
    const st = s.structure();

    inline for (fields) |field| {
        if (field.type != void) {
            // The name of the field to be deserialized.
            comptime var name: []const u8 = field.name;

            // Process attributes.
            if (attributes) |attrs| {
                if (@hasField(@TypeOf(attrs), field.name)) {
                    const attr = @field(attrs, field.name);

                    if (@hasField(@TypeOf(attr), "skip") and attr.skip) {
                        continue;
                    }

                    if (@hasField(@TypeOf(attr), "rename")) {
                        name = attr.rename;
                    }
                }
            }

            // Serialize field.
            try st.serializeField(name, @field(value, field.name));
        }
    }

    return try st.end();
}

test "serialize - struct" {
    const Struct = struct { a: i32, b: i32, c: i32 };

    try t.ser.run(Struct{ .a = 1, .b = 2, .c = 3 }, &[_]t.Token{
        .{ .Struct = .{ .name = @typeName(Struct), .len = 3 } },
        .{ .String = "a" },
        .{ .I32 = 1 },
        .{ .String = "b" },
        .{ .I32 = 2 },
        .{ .String = "c" },
        .{ .I32 = 3 },
        .{ .StructEnd = {} },
    });
}
