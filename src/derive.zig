const std = @import("std");
const expect = std.testing.expect;

const Ser = @import("ser.zig").Serialize;
const Serializer = @import("ser.zig").Serializer;
const SerError = @import("ser.zig").Error;
const De = @import("de.zig").Deserialize;
const Deserializer = @import("de.zig").Deserializer;
const DeError = @import("de.zig").Error;

/// Provides a generic implementation of `getty.ser.Serialize.serialize`.
pub fn Serialize(comptime T: type, comptime attributes: Attributes(T, .ser)) type {
    return struct {
        pub const ser = Ser{ .serialize_fn = serialize };

        pub fn serialize(self: *const Ser, serializer: Serializer) SerError!void {
            switch (@typeInfo(T)) {
                .AnyFrame => {},
                .Array => {},
                .Bool => std.log.warn("Serialize.serialize -> Bool", .{}),
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
                .Struct => {
                    std.log.warn("Serialize.serialize -> Struct", .{});
                    //if (std.meta.fields(@TypeOf(attributes)).len == 0) {
                    //const fields = std.meta.fields(T);
                    //var s = try serializer.serialize_struct(@typeName(T), fields.len);

                    //for (fields) |field| {
                    //try s.serialize_field(field.name, @field(self, field.name));
                    //}
                    //} else {
                    //const fields = std.meta.fields(@TypeOf(attributes));

                    //for (fields) |field| {
                    //if (std.mem.eql(u8, field.name, @typeName(T)) {
                    // Container attribute

                    //} else {
                    // Field/variant attribute
                    //}
                    //}
                    //}

                    //const container_name = @field(serializer, @typeName(T));
                    //std.debug.warn("{}", .{container_name});

                    //s.end()
                },
                .Type => {},
                .Undefined => {},
                .Union => {},
                .Vector => {},
                .Void => {},
            }
        }
    };
}

/// Provides a generic implementation of `getty.de.Deserialize.deserialize`.
pub fn Deserialize(comptime T: type, comptime attributes: Attributes(T, .de)) type {
    return struct {
        pub const de = De{ .deserialize_fn = deserialize };

        pub fn deserialize(self: *const De, deserializer: Deserializer) DeError!void {
            switch (@typeInfo(T)) {
                .AnyFrame => {},
                .Array => {},
                .Bool => {
                    std.log.warn("Deserialize.deserialize -> Bool", .{});
                },
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
                .Struct => {
                    std.log.warn("Deserialize.deserialize -> Struct", .{});
                },
                .Type => {},
                .Undefined => {},
                .Union => {},
                .Vector => {},
                .Void => {},
            }
        }
    };
}

/// Returns an attribute map type.
///
/// `T` is a type that wants to implement the `Deserialize` interface.
///
/// The returned type is a struct that contains fields corresponding to each
/// field/variant in `T`, as well as a field named after `T`. These identifier
/// fields are structs containing various attributes. The attributes within an
/// identifier field depend on the identifier field. For identifier fields that
/// correspond to a field or variant in `T`, the attributes consists of field
/// or variant attributes. For the identifier field corresponding to the type
/// name of `T`, the attributes consist of container attributes. All fields in
/// `attributes` may be omitted.
fn Attributes(comptime T: type, mode: enum { ser, de }) type {
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
        usingnamespace Serialize(@This(), .{});

        x: i32,
        y: i32,
    };

    var point = TestPoint{ .x = 1, .y = 2 };
    var test_serializer = TestSerializer.init(std.testing.allocator);
    defer test_serializer.deinit();

    var serialize = &(@TypeOf(point).ser);
    var serializer = &(@TypeOf(test_serializer).serializer);
    try serialize.serialize(serializer.*);
    try serializer.serialize_bool(true);
}

test "Serialize - with container attribute (struct)" {
    const TestPoint = struct {
        usingnamespace Serialize(@This(), .{ .TestPoint = .{ .rename = "A" } });

        x: i32,
        y: i32,
    };
}

test "Serialize - with field attribute (struct)" {
    const TestPoint = struct {
        usingnamespace Serialize(@This(), .{ .x = .{ .rename = "a" } });

        x: i32,
        y: i32,
    };
}

test "Deserialize - basic (struct)" {
    const TestPoint = struct {
        usingnamespace Deserialize(@This(), .{});

        x: i32,
        y: i32,
    };
}

test "Deserialize - with container attribute (struct)" {
    const TestPoint = struct {
        usingnamespace Deserialize(@This(), .{ .TestPoint = .{ .rename = "A" } });

        x: i32,
        y: i32,
    };
}

test "Deserialize - with field attribute (struct)" {
    const TestPoint = struct {
        usingnamespace Deserialize(@This(), .{ .x = .{ .rename = "a" } });

        x: i32,
        y: i32,
    };
}

const TestSerializer = struct {
    output: std.ArrayList(u8),

    fn init(allocator: *std.mem.Allocator) @This() {
        return .{ .output = std.ArrayList(u8).init(allocator) };
    }

    fn deinit(self: @This()) void {
        self.output.deinit();
    }

    const serializer = Serializer{
        .bool_fn = serialize_bool,
        .i8_fn = serialize_i8,
        .i16_fn = serialize_i16,
        .i32_fn = serialize_i32,
        .i64_fn = serialize_i64,
        .i128_fn = serialize_i128,
        .u8_fn = serialize_u8,
        .u16_fn = serialize_u16,
        .u32_fn = serialize_u32,
        .u64_fn = serialize_u64,
        .u128_fn = serialize_u128,
        .f16_fn = serialize_f16,
        .f32_fn = serialize_f32,
        .f64_fn = serialize_f64,
    };

    fn serialize_bool(self: *const Serializer, v: bool) SerError!void {
        std.log.warn("TestSerializer.serialize_bool", .{});
    }

    fn serialize_i8(self: *const Serializer, v: i8) SerError!void {
        std.log.warn("TestSerializer.serialize_i8", .{});
    }

    fn serialize_i16(self: *const Serializer, v: i16) SerError!void {
        std.log.warn("TestSerializer.serialize_i16", .{});
    }

    fn serialize_i32(self: *const Serializer, v: i32) SerError!void {
        std.log.warn("TestSerializer.serialize_i32", .{});
    }

    fn serialize_i64(self: *const Serializer, v: i64) SerError!void {
        std.log.warn("TestSerializer.serialize_i64", .{});
    }

    fn serialize_i128(self: *const Serializer, v: i128) SerError!void {
        std.log.warn("TestSerializer.serialize_i128", .{});
    }

    fn serialize_u8(self: *const Serializer, v: u8) SerError!void {
        std.log.warn("TestSerializer.serialize_u8", .{});
    }

    fn serialize_u16(self: *const Serializer, v: u16) SerError!void {
        std.log.warn("TestSerializer.serialize_u16", .{});
    }

    fn serialize_u32(self: *const Serializer, v: u32) SerError!void {
        std.log.warn("TestSerializer.serialize_u32", .{});
    }

    fn serialize_u64(self: *const Serializer, v: u64) SerError!void {
        std.log.warn("TestSerializer.serialize_u64", .{});
    }

    fn serialize_u128(self: *const Serializer, v: u128) SerError!void {
        std.log.warn("TestSerializer.serialize_u128", .{});
    }

    fn serialize_f16(self: *const Serializer, v: f16) SerError!void {
        std.log.warn("TestSerializer.serialize_f16", .{});
    }

    fn serialize_f32(self: *const Serializer, v: f32) SerError!void {
        std.log.warn("TestSerializer.serialize_f32", .{});
    }

    fn serialize_f64(self: *const Serializer, v: f64) SerError!void {
        std.log.warn("TestSerializer.serialize_f64", .{});
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
