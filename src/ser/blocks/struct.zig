const std = @import("std");
const t = @import("getty/testing");

const ser = @import("../ser.zig");

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

    // Get number of fields that will actually be serialized.
    const length: usize = comptime blk: {
        var len: usize = fields.len;

        if (attributes) |attrs| {
            for (std.meta.fields(@TypeOf(attrs))) |attr_field| {
                const attr = @field(attrs, attr_field.name);

                if (@hasField(@TypeOf(attr), "skip") and attr.skip) {
                    len -= 1;
                }
            }
        }

        break :blk len;
    };

    var s = try serializer.serializeStruct(@typeName(T), length);
    const st = s.structure();

    inline for (fields) |field| {
        if (field.type != void) {
            // The name of the field to be serialized.
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
    const T = struct { a: i32, b: i32, c: i32, d: i32 };
    const v = T{ .a = 1, .b = 2, .c = 3, .d = 4 };

    try t.ser.run(serialize, v, &.{
        .{ .Struct = .{ .name = @typeName(T), .len = 4 } },
        .{ .String = "a" },
        .{ .I32 = 1 },
        .{ .String = "b" },
        .{ .I32 = 2 },
        .{ .String = "c" },
        .{ .I32 = 3 },
        .{ .String = "d" },
        .{ .I32 = 4 },
        .{ .StructEnd = {} },
    });
}

test "serialize - struct, attributes (rename)" {
    const T = struct {
        a: i32,
        b: i32,
        c: i32,
        d: i32,

        pub const @"getty.sb" = struct {
            pub const attributes = .{
                .a = .{ .rename = "d" },
                .b = .{ .rename = "c" },
                .c = .{ .rename = "b" },
                .d = .{ .rename = "a" },
            };
        };
    };
    const v = T{ .a = 1, .b = 2, .c = 3, .d = 4 };

    try t.ser.run(serialize, v, &.{
        .{ .Struct = .{ .name = @typeName(T), .len = 4 } },
        .{ .String = "d" },
        .{ .I32 = 1 },
        .{ .String = "c" },
        .{ .I32 = 2 },
        .{ .String = "b" },
        .{ .I32 = 3 },
        .{ .String = "a" },
        .{ .I32 = 4 },
        .{ .StructEnd = {} },
    });
}

test "serialize - struct, attributes (skip)" {
    const T = struct {
        a: i32,
        b: i32,
        c: i32,
        d: i32,

        pub const @"getty.sb" = struct {
            pub const attributes = .{
                .b = .{ .skip = true },
                .c = .{ .skip = true },
            };
        };
    };

    const v = T{ .a = 1, .b = 2, .c = 3, .d = 4 };

    try t.ser.run(serialize, v, &.{
        .{ .Struct = .{ .name = @typeName(T), .len = 2 } },
        .{ .String = "a" },
        .{ .I32 = 1 },
        .{ .String = "d" },
        .{ .I32 = 4 },
        .{ .StructEnd = {} },
    });
}
