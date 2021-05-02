const std = @import("std");
const expect = std.testing.expect;

const ser = @import("ser.zig");
const de = @import("de.zig");

/// Provides a generic implementation of `getty.ser.Serialize.serialize`.
pub fn Serialize(comptime T: type, comptime attributes: Attributes(T, .ser)) type {
    return struct {
        pub const Ser = ser.Serialize(*T, serialize);

        pub fn ser(self: *T) Ser {
            return .{ .context = self };
        }

        pub fn serialize(self: *T, comptime S: type, serializer: *S) Error!Ok {
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

// Provides a generic implementation of `getty.de.Deserialize.deserialize`.
//pub fn Deserialize(comptime T: type, comptime attributes: Attributes(T, .de)) type {
//return struct {
//pub const De = de.Deserialize(*@This(), deserialize);

//pub fn deserialize(self: *@This(), deserializer: _de.Deserializer) _de.Deserialize.Error!void {
//switch (@typeInfo(T)) {
//.AnyFrame => {},
//.Array => {},
//.Bool => {
//std.log.warn("Deserialize.deserialize -> Bool", .{});
//},
//.BoundFn => {},
//.ComptimeFloat => {},
//.ComptimeInt => {},
//.Enum => {},
//.EnumLiteral => {},
//.ErrorSet => {},
//.ErrorUnion => {},
//.Float => {},
//.Fn => {},
//.Frame => {},
//.Int => {},
//.NoReturn => {},
//.Null => {},
//.Opaque => {},
//.Optional => {},
//.Pointer => {},
//.Struct => {
//std.log.warn("Deserialize.deserialize -> Struct", .{});
//},
//.Type => {},
//.Undefined => {},
//.Union => {},
//.Vector => {},
//.Void => {},
//}
//}
//};
//}

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

    var serialize = point.ser();
    var serializer = test_serializer.serializer();
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

//test "Deserialize - basic (struct)" {
//const TestPoint = struct {
//usingnamespace Deserialize(@This(), .{});

//x: i32,
//y: i32,
//};
//}

//test "Deserialize - with container attribute (struct)" {
//const TestPoint = struct {
//usingnamespace Deserialize(@This(), .{ .TestPoint = .{ .rename = "A" } });

//x: i32,
//y: i32,
//};
//}

//test "Deserialize - with field attribute (struct)" {
//const TestPoint = struct {
//usingnamespace Deserialize(@This(), .{ .x = .{ .rename = "a" } });

//x: i32,
//y: i32,
//};
//}

const TestSerializer = struct {
    output: std.ArrayList(u8),

    fn init(allocator: *std.mem.Allocator) @This() {
        return .{ .output = std.ArrayList(u8).init(allocator) };
    }

    fn deinit(self: @This()) void {
        self.output.deinit();
    }

    const Ok = void;
    const Error = error{};

    const Serializer = ser.Serializer(
        *@This(),
        Ok,
        Error,
        serialize_bool,
        serialize_int,
        serialize_f16,
        serialize_f32,
        serialize_f64,
    );

    fn serializer(self: *@This()) Serializer {
        return .{ .context = self };
    }

    fn serialize_bool(self: *@This(), v: bool) Error!Ok {
        std.log.warn("TestSerializer.serialize_bool", .{});
    }

    fn serialize_int(self: *@This(), v: anytype) Error!Ok {
        std.log.warn("TestSerializer.serialize_int", .{});
    }

    fn serialize_f16(self: *@This(), v: f16) Error!Ok {
        std.log.warn("TestSerializer.serialize_f16", .{});
    }

    fn serialize_f32(self: *@This(), v: f32) Error!Ok {
        std.log.warn("TestSerializer.serialize_f32", .{});
    }

    fn serialize_f64(self: *@This(), v: f64) Error!Ok {
        std.log.warn("TestSerializer.serialize_f64", .{});
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
