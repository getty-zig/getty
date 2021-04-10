const std = @import("std");

const attr = @import("../attribute.zig");
const Serializer = @import("../serialize.zig").Serializer;

/// Provides a generic implementation of `getty.ser.Serialize.serialize`.
pub fn Serialize(comptime T: type, comptime attributes: Attributes(T)) type {
    return struct {
        pub fn serialize(self: *T, serializer: Serializer) void {
            switch (@typeInfo(T)) {
                .AnyFrame => {},
                .Array => {},
                .Bool => std.log.warn("Serialize.serialize -> Bool\n", .{}),
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
                    std.log.warn("Serialize.serialize -> Struct\n", .{});
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
                    //std.debug.warn("{}\n", .{container_name});

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

/// Returns an attribute map type.
///
/// `T` is a type that wants to implement the `Serialize` interface.
///
/// The returned type is a struct that contains fields corresponding to each
/// field/variant in `T`, as well as a field named after `T`. These identifier
/// fields are structs containing various attributes. The attributes within an
/// identifier field depend on the identifier field. For identifier fields that
/// correspond to a field or variant in `T`, the attributes consists of field
/// or variant attributes. For the identifier field corresponding to the type
/// name of `T`, the attributes consist of container attributes. All fields in
/// `attributes` may be omitted.
///
/// # Examples
///
/// ```
/// const A = struct {
///    // struct {
///    //     .A: struct { <container attributes> },
///    //     .a: struct { <field attributes> },
///    //     .b: struct { <field attributes> },
///    // };
///    usingnamespace Serialize(@This(), .{});
///
///     a: i32,
///     b: i32,
/// };
///
/// const B = struct {
///    // struct {
///    //     .B: struct { <container attributes> },
///    //     .c: struct { <field attributes> },
///    //     .d: struct { <field attributes> },
///    // };
///    usingnamespace Serialize(@This(), .{
///        .B = .{ .rename = "C", .rename_all = "lowercase" },
///        .c = .{ .rename = "z" },
///    });
///
///     c: i32,
///     d: i32,
/// };
/// ```
fn Attributes(comptime T: type) type {
    const Container = struct {
        //bound: ,
        //content: ,
        into: []const u8 = "",
        rename: []const u8 = @typeName(T),
        rename_all: []const u8 = "",
        //remote: ,
        //tag: ,
        transparent: bool = false,
        //untagged: ,
    };
    const Field = struct {
        //bound: ,
        //flatten: ,
        //getter: ,
        rename: []const u8 = @typeName(T),
        skip: bool = false,
        //skip_serializing_if: ,
        with: []const u8 = "",
    };
    const Variant = struct {
        //bound: ,
        rename: []const u8 = "",
        rename_all: []const u8 = "",
        skip: bool = false,
        with: []const u8 = "",
    };

    const container_attrs = Container{};
    const field_attrs = Field{};
    const variant_attrs = Variant{};

    comptime var fields: [std.meta.fields(T).len + 1]std.builtin.TypeInfo.StructField = undefined;

    // field/variant
    inline for (std.meta.fields(T)) |field, i| {
        fields[i] = switch (@typeInfo(T)) {
            .Struct => .{
                .name = field.name,
                .field_type = Field,
                .default_value = field_attrs,
                .is_comptime = true,
                .alignment = 4,
            },
            .Enum => .{
                .name = field.name,
                .field_type = Variant,
                .default_value = variant_attrs,
                .is_comptime = true,
                .alignment = 4,
            },
            else => unreachable, // TODO: Is this really unreachable?
        };
    }

    // container
    fields[fields.len - 1] = .{
        .name = @typeName(T),
        .field_type = Container,
        .default_value = container_attrs,
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

const expect = std.testing.expect;

test "Serialize - basic (struct)" {
    const T = struct {
        usingnamespace Serialize(@This(), .{});

        x: i32,
        y: i32,
    };
}

test "Serialize - with container attribute (struct)" {
    const T = struct {
        usingnamespace Serialize(@This(), .{ .T = .{ .rename = "A" } });

        x: i32,
        y: i32,
    };
}

test "Serialize - with field attribute (struct)" {
    const T = struct {
        usingnamespace Serialize(@This(), .{ .x = .{ .rename = "a" } });

        x: i32,
        y: i32,
    };
}

comptime {
    std.testing.refAllDecls(@This());
}
