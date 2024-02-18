//! `Struct` is a _Serialization Block_ for struct values.

const std = @import("std");

const getAttributes = @import("../attributes.zig").getAttributes;
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Struct and !@typeInfo(T).Struct.is_tuple;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Err!@TypeOf(serializer).Ok {
    _ = ally;

    const T = @TypeOf(value);
    const fields = std.meta.fields(T);
    const attributes = comptime getAttributes(T, @TypeOf(serializer));

    // The number of fields that will be serialized.
    //
    // length is initially set to the number of fields in the struct, but is
    // decremented for any field that has the "skip" attribute set.
    var length: usize = comptime blk: {
        var len: usize = fields.len;

        if (attributes) |attrs| {
            for (std.meta.fields(@TypeOf(attrs))) |field| {
                const attr = @field(attrs, field.name);

                const skipped = @hasField(@TypeOf(attr), "skip") and attr.skip;
                if (skipped) {
                    len -= 1;
                    continue;
                }
            }
        }

        break :blk len;
    };

    inline for (fields) |field| {
        const attrs = comptime blk: {
            if (attributes) |attrs| {
                if (@hasField(@TypeOf(attrs), field.name)) {
                    const a = @field(attrs, field.name);
                    const A = @TypeOf(a);

                    break :blk @as(?A, a);
                }
            }

            break :blk null;
        };

        if (attrs) |a| {
            const skip_if = @hasField(@TypeOf(a), "skip_ser_if");
            if (skip_if and a.skip_ser_if(@field(value, field.name))) {
                length -= 1;
            }
        }
    }

    var s = try serializer.serializeStruct(@typeName(T), length);
    const st = s.structure();

    inline for (fields) |field| {
        const attrs = comptime blk: {
            if (attributes) |attrs| {
                if (@hasField(@TypeOf(attrs), field.name)) {
                    const a = @field(attrs, field.name);
                    const A = @TypeOf(a);

                    break :blk @as(?A, a);
                }
            }

            break :blk null;
        };

        var skip: bool = undefined;
        if (attrs) |a| {
            const skipped = @hasField(@TypeOf(a), "skip") and a.skip;
            if (skipped) continue;

            const skip_if = @hasField(@TypeOf(a), "skip_ser_if");
            if (skip_if and a.skip_ser_if(@field(value, field.name))) {
                skip = true;
            }
        }

        // This is needed because we can't call skip_ser_if at compile-time, so
        // we can't continue the inlined loop.
        if (!skip) {
            // The name that will be used when serializing field.
            //
            // Initially, name is set to field's name. But field has the "rename"
            // attribute set, name is set to the attribute's value.
            const name = comptime blk: {
                var n = field.name;

                if (attrs) |a| {
                    const renamed = @hasField(@TypeOf(a), "rename");
                    if (renamed) n = a.rename;
                }

                break :blk n;
            };

            try st.serializeField(name, @field(value, field.name));
        }
    }

    return try st.end();
}

test "serialize - struct" {
    const T = struct { a: i32, b: i32, c: i32, d: i32 };
    const v = T{ .a = 1, .b = 2, .c = 3, .d = 4 };

    try t.run(null, serialize, v, &.{
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

test "serialize - struct (void)" {
    const T = struct { a: void, b: void };
    const v = T{ .a = {}, .b = {} };

    try t.run(null, serialize, v, &.{
        .{ .Struct = .{ .name = @typeName(T), .len = 2 } },
        .{ .String = "a" },
        .{ .Void = {} },
        .{ .String = "b" },
        .{ .Void = {} },
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

    try t.run(null, serialize, v, &.{
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

    try t.run(null, serialize, v, &.{
        .{ .Struct = .{ .name = @typeName(T), .len = 2 } },
        .{ .String = "a" },
        .{ .I32 = 1 },
        .{ .String = "d" },
        .{ .I32 = 4 },
        .{ .StructEnd = {} },
    });
}

test "serialize - struct, attributes (skip_ser_if)" {
    const T = struct {
        a: i32,
        b: i32,
        c: ?i32,
        d: ?i32,

        pub const @"getty.sb" = struct {
            pub const attributes = .{
                .a = .{ .skip_ser_if = isNull },
                .b = .{ .skip_ser_if = isNull },
                .c = .{ .skip_ser_if = isNull },
                .d = .{ .skip_ser_if = isNull },
            };
        };
    };

    const v = T{ .a = 1, .b = 2, .c = null, .d = 4 };

    try t.run(null, serialize, v, &.{
        .{ .Struct = .{ .name = @typeName(T), .len = 3 } },
        .{ .String = "a" },
        .{ .I32 = 1 },
        .{ .String = "b" },
        .{ .I32 = 2 },
        .{ .String = "d" },
        .{ .Some = {} },
        .{ .I32 = 4 },
        .{ .StructEnd = {} },
    });
}

fn isNull(v: anytype) bool {
    return switch (@typeInfo(@TypeOf(v))) {
        .Null, .Optional => v == null,
        else => false,
    };
}
