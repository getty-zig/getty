const de = @import("de.zig");
const ser = @import("ser.zig");
const std = @import("std");

const mem = std.mem;
const meta = std.meta;
const trait = meta.trait;
const testing = std.testing;

const TypeInfo = std.builtin.TypeInfo;

pub const Case = enum {
    lower,
    upper,
    pascal,
    camel,
    snake,
    screaming_snake,
    kebab,
    screaming_kebab,
};

/// Specifies container and field/variant attributes for a struct or enum.
///
/// The function returns an anonymous struct that contains a declaration named
/// `_getty_attributes`. This declaration should be imported into the caller's
/// struct or enum via `usingnamespace`.
///
/// For more information on the anonymous struct returned, see the
/// documentation for `_Attributes`.
pub fn Attributes(comptime T: type, attributes: anytype) type {
    return struct {
        pub const _getty_attributes: _Attributes(T, attributes) = attributes;

        // This isn't needed for actual usage. But when testing, invalid
        // fields/values aren't picked up unless we reference
        // _getty_attributes.
        comptime {
            inline for (meta.declarations(@This())) |decl| {
                _ = decl;
            }
        }
    };
}

/// Returns an attribute map type.
///
/// The returned type is a struct that contains fields corresponding to either
/// fields in the struct/enum for which attributes are being specified or the
/// the struct/enum itself. Only the fields of the attributes passed in
/// (assuming they are all valid) will be present in the returned type.
///
/// These "identifier fields" are themselves structs. Their fields depend on
/// whether they correspond to a field/variant or the container type. In the
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
///     usingnamespace getty.Attributes(Point, .{ .x = .{ .rename = "a" } } );
///
///     x: i32,
///     y: i32,
/// };
/// ```
///
/// `getty.Attributes` would expect as its second parameter a value of the
/// following type:
///
/// ```
/// struct {
///     x: struct {
///         .rename: ?[]const u8 = null,
///         // ... other field attributes
///     },
/// }
/// ```
///
/// Now, suppose you specify a container attribute as well:
///
/// ```
/// const Point = struct {
///     usingnamespace getty.Attributes(Point, .{
///         .Point = .{ .rename = "MyPoint" },
///         .x = .{ .rename = "a" },
///     } );
///
///     x: i32,
///     y: i32,
/// };
/// ```
///
/// Then, `getty.Attributes` would expect as its second parameter a value of the
/// following type:
///
/// ```
/// struct {
///     Point: struct {
///         rename: ?[]const u8 = null,
///         // ... other container attributes
///     },
///
///     x: struct {
///         rename: ?[]const u8 = null,
///         // ... other field attributes
///     },
/// }
/// ```
fn _Attributes(comptime T: type, attributes: anytype) type {
    const A = @TypeOf(attributes);

    if (@typeInfo(A) != .Struct) {
        @compileError("expected attribute map, found " ++ @typeName(A));
    }

    if (meta.fields(A).len == 0) {
        return struct {};
    }

    const Container = struct {
        //content: ?[]const u8 = null,

        // When deserializing, any missing fields should be filled in from the
        // field's default value.
        default: bool = false,

        // When deserializing, any missing fields should be filled in from the
        // object returned by the given function.
        //
        // Overrides `default`.
        default_path: ?[]const u8 = null,

        // Always error during deserialization when encountering unknown fields.
        //
        // This attribute isn't compatible with `flatten`.
        deny_unknown_fields: bool = false,

        // Deserialize this type by deserializing into the given type, then
        // converting.
        from: ?[]const u8 = null,

        // Serialize this type by converting it into the specified type and
        // serializing that.
        into: ?[]const u8 = null,

        // Serialize and deserialize this struct with the given name instead of
        // its type name.
        rename: []const u8 = @typeName(T),

        // Deserialize this struct with the given name instead of its type
        // name.
        //
        // Overrides `rename`.
        rename_de: []const u8 = @typeName(T),

        // Serialize this struct with the given name instead of its type name.
        //
        // Overrides `rename`.
        rename_ser: []const u8 = @typeName(T),

        // Rename all the fields of this struct according to the given case
        // convention.
        rename_all: ?Case = null,

        // Rename all the fields of this struct during deserialization
        // according to the given case convention.
        //
        // Overrides `rename_all`.
        rename_all_de: ?Case = null,

        // Rename all the fields of this struct during serialization according
        // to the given case convention.
        //
        // Overrides `rename_all`.
        rename_all_ser: ?Case = null,

        // Use the internally tagged enum representation for this enum, with
        // the given tag.
        //tag: ?[]const u8 = null,

        // Deserialize this type by deserializing into the given type, then
        // converting fallibly.
        try_from: ?[]const u8 = null,

        // Use the untagged enum representation for this enum.
        untagged: bool = false,
    };

    const Inner = switch (@typeInfo(T)) {
        .Struct => struct {
            // Deserialize this field from the given names *or* its type
            // name.
            alias: ?[][]const u8 = null,

            // If the value is not present when deserializing, use the
            // field's default value.
            default: bool = false,

            // If the value is not present when deserializing, call a
            // function to get a default value.
            //
            // Overrides `default`.
            default_path: ?[]const u8 = null,

            // Deserialize this field using a function that is different
            // from the normal deserialization implementation.
            deserialize_with: ?[]const u8 = null,

            // Flatten the contents of this field into the container it is
            // defined in.
            //
            // This attribute is not compatible with the
            // deny_unknown_fields attribute.
            flatten: bool = false,

            // Serialize and deserialize this field with the given name
            // instead of its type name.
            rename: ?[]const u8 = null,

            // Deserialize this field with the given name instead of its
            // type name.
            //
            // Overrides `rename`.
            rename_de: ?[]const u8 = null,

            // Serialize this field with the given name instead of its
            // type name.
            //
            // Overrides `rename`.
            rename_ser: ?[]const u8 = null,

            // Skip this field during serialization and deserialziation.
            //
            // During deserialization, the field's default value will be
            // used.
            skip: bool = false,

            // Skip this field during deserialization.
            //
            // The field's default value will be used.
            //
            // Overrides `skip`.
            skip_de: bool = false,

            // Skip this field during serialization.
            //
            // Overrides `skip`.
            skip_ser: bool = false,

            // Call a function to determine whether to skip serializing
            // this field.
            skip_ser_if: ?[]const u8 = null,

            // Serialize this field using a function that is different from
            // the normal serialization implementation.
            serialize_with: ?[]const u8 = null,

            // Combination of serialize_with and deserialize_with.
            with: ?[]const u8 = null,
        },
        .Enum => struct {
            // Deserialize this variant from the given names *or* its type
            // name.
            alias: ?[][]const u8 = null,

            // Deserialize this variant using a function that is different
            // from the normal deserialization implementation.
            deserialize_with: ?[]const u8 = null,

            // Serialize and deserialize this variant with the given name
            // instead of its type name.
            rename: ?[]const u8 = null,

            // Deserialize this variant with the given name instead of its
            // type name.
            //
            // Overrides `rename`.
            rename_de: ?[]const u8 = null,

            // Serialize this variant with the given name instead of its
            // type name.
            //
            // Overrides `rename`.
            rename_ser: ?[]const u8 = null,

            // Never serialize or deserialize this variant.
            skip: bool = false,

            // Never serialize this variant.
            //
            // Overrides `skip`.
            skip_de: bool = false,

            // Never deserialize this variant.
            //
            // Overrides `skip`.
            skip_ser: bool = false,

            // Serialize this variant using a function that is different from
            // the normal serialization implementation.
            serialize_with: ?[]const u8 = null,

            // Combination of serialize_with and deserialize_with.
            with: ?[]const u8 = null,
        },
        else => unreachable,
    };

    const container = Container{};
    const inner = Inner{};

    comptime var fields: [meta.fields(A).len]TypeInfo.StructField = undefined;

    inline for (meta.fields(A)) |field, i| {
        if (comptime meta.trait.hasField(field.name)(T)) {
            fields[i] = .{
                .name = field.name,
                .field_type = Inner,
                .default_value = inner,
                .is_comptime = false,
                .alignment = 4,
            };
        } else if (comptime mem.eql(u8, field.name, @typeName(T))) {
            fields[i] = .{
                .name = @typeName(T),
                .field_type = Container,
                .default_value = container,
                .is_comptime = false,
                .alignment = 4,
            };
        } else {
            @compileError("invalid field: " ++ field.name);
        }
    }

    return @Type(TypeInfo{
        .Struct = .{
            .layout = .Auto,
            .fields = &fields,
            .decls = &[_]TypeInfo.Declaration{},
            .is_tuple = false,
        },
    });
}

comptime {
    testing.refAllDecls(@This());
}
