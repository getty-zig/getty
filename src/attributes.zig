const de = @import("de.zig");
const ser = @import("ser.zig");
const std = @import("std");

pub const Mode = enum {
    ser,
    de,
};

/// Returns an attribute map type.
///
/// The returned type is a struct that contains:
///
///  - Fields named after each field/variant in `T`.
///  - One field named after `T` itself.
///
/// These "identifier fields" are themselves structs. Their fields depend on
/// whether they are named after a field/variant or the container type. In the
/// former case, the inner fields correspond to field/variant attributes. In
/// the latter case, the inner fields correspond to container attributes.
///
/// All fields in the returned type may be omitted.
///
/// ## Example
///
/// Consider the following type:
///
/// ```
/// const Point = struct {
///     x: i32,
///     y: i32,
/// };
/// ```
///
/// In this case, `getty.Attributes` would expect for its second parameter a
/// value of the following type:
///
/// ```
/// struct {
///     Point: struct {
///         into: []const u8 = "",
///         rename: []const u8 = @typeName(Point),
///         rename_all: []const u8 = "",
///         transparent: bool = false,
///     },
///
///     x: struct {
///         rename: []const u8 = @typeName(Point),
///         skip: bool = false,
///         with: []const u8 = "",
///     },
///
///     y: struct {
///         rename: []const u8 = @typeName(Point),
///         skip: bool = false,
///         with: []const u8 = "",
///     },
/// }
/// ```
///
/// Thus, an example usage could look like this:
///
/// ```
/// const getty = @import("getty");
///
/// const Point = struct {
///     usingnamespace getty.Attributes(@This(), .{
///         .Point = .{ .rename = "MyPoint" },
///         .x = .{ .skip = true },
///     });
///
///     x: i32,
///     y: i32,
/// };
/// ```
pub fn Attributes(comptime T: type, comptime mode: Mode, attributes: _Attributes(T, mode)) type {
    return struct {
        pub const _attributes = attributes;
    };
}

/// Returns an attribute map type.
///
/// See `Attributes` for more information.
fn _Attributes(comptime T: type, comptime mode: Mode) type {
    const Container = switch (mode) {
        .ser => struct {
            //bound: ,
            //content: ,
            into: []const u8 = "",
            rename: []const u8 = @typeName(T),
            rename_all: []const u8 = "",
            //remote: ,
            //tag: ,
            transparent: bool = false,
            //untagged: ,
        },
        .de => struct {
            //bound: ,
            //content: ,
            //default: ,
            deny_unknown_fields: bool = false,
            //from: ,
            into: []const u8 = "",
            rename: []const u8 = @typeName(T),
            rename_all: []const u8 = "",
            //remote: ,
            //tag: ,
            transparent: bool = false,
            //try_from:,
            //untagged: ,
        },
    };

    const Inner = switch (mode) {
        .ser => switch (@typeInfo(T)) {
            .Struct => struct {
                //bound: ,
                //flatten: ,
                //getter: ,
                rename: []const u8 = @typeName(T),
                skip: bool = false,
                //skip_serializing_if: ,
                with: []const u8 = "",
            },
            .Enum => struct {
                //bound: ,
                rename: []const u8 = "",
                rename_all: []const u8 = "",
                skip: bool = false,
                with: []const u8 = "",
            },
            else => unreachable,
        },
        .de => switch (@typeInfo(T)) {
            .Struct => struct {
                alias: []const u8 = "",
                //bound: ,
                //default: ,
                //flatten: ,
                rename: []const u8 = @typeName(T),
                skip: bool = false,
                with: []const u8 = "",
            },
            .Enum => struct {
                alias: []const u8 = "",
                //bound: ,
                other: bool = false,
                rename: []const u8 = @typeName(T),
                rename_all: []const u8 = "",
                skip: bool = false,
                with: []const u8 = "",
            },
            else => unreachable,
        },
    };

    const container = Container{};
    const inner = Inner{};

    comptime var fields: [std.meta.fields(T).len + 1]std.builtin.TypeInfo.StructField = undefined;

    inline for (std.meta.fields(T)) |field, i| {
        fields[i] = .{
            .name = field.name,
            .field_type = Inner,
            .default_value = inner,
            .is_comptime = true,
            .alignment = 4,
        };
    }

    fields[fields.len - 1] = .{
        .name = @typeName(T),
        .field_type = Container,
        .default_value = container,
        .is_comptime = true,
        .alignment = 4,
    };

    return @Type(std.builtin.TypeInfo{
        .Struct = .{
            .layout = .Auto,
            .fields = &fields,
            .decls = &[_]std.builtin.TypeInfo.Declaration{},
            .is_tuple = false,
        },
    });
}

test "Serialize - basic (struct)" {
    const TestPoint = struct {
        usingnamespace Attributes(@This(), .ser, .{});

        x: i32,
        y: i32,
    };
}

test "Serialize - with container attribute (struct)" {
    const TestPoint = struct {
        usingnamespace Attributes(@This(), .ser, .{ .TestPoint = .{ .rename = "A" } });

        x: i32,
        y: i32,
    };
}

test "Serialize - with field attribute (struct)" {
    const TestPoint = struct {
        usingnamespace Attributes(@This(), .ser, .{ .x = .{ .rename = "a" } });

        x: i32,
        y: i32,
    };
}
