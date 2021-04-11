const std = @import("std");

/// Provides a generic implementation of `getty.de.Deserialize.deserialize`.
pub fn Deserialize(comptime T: type, comptime attributes: Attributes(T)) type {
    return struct {
        pub fn _deserialize(self: *T) de.Deserialize(*T, deserialize) {
            return .{ .context = self };
        }

        pub fn deserialize(self: *T, deserializer: de.Deserializer) void {
            switch (@typeInfo(T)) {
                .AnyFrame => {},
                .Array => {},
                .Bool => {
                    std.log.warn("Deserialize.deserialize -> Bool\n", .{});
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
                    std.log.warn("Deserialize.deserialize -> Struct\n", .{});
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
///    usingnamespace Deserialize(@This(), .{});
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
///    usingnamespace Deserialize(@This(), .{
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
    };
    const Field = struct {
        alias: []const u8 = "",
        //bound: ,
        //default: ,
        //flatten: ,
        rename: []const u8 = @typeName(T),
        skip: bool = false,
        with: []const u8 = "",
    };
    const Variant = struct {
        alias: []const u8 = "",
        //bound: ,
        other: bool = false,
        rename: []const u8 = @typeName(T),
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

test "Deserialize - basic (struct)" {
    const T = struct {
        usingnamespace Deserialize(@This(), .{});

        x: i32,
        y: i32,
    };
}

test "Deserialize - with container attribute (struct)" {
    const T = struct {
        usingnamespace Deserialize(@This(), .{ .T = .{ .rename = "A" } });

        x: i32,
        y: i32,
    };
}

test "Deserialize - with field attribute (struct)" {
    const T = struct {
        usingnamespace Deserialize(@This(), .{ .x = .{ .rename = "a" } });

        x: i32,
        y: i32,
    };
}

comptime {
    std.testing.refAllDecls(@This());
}
