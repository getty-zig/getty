const std = @import("std");

const Type = std.builtin.Type;

const ContainerAttributes = struct {
    //content: ?[]const u8 = null,

    // When deserializing, any missing fields should be filled in from the
    // field's default value.
    //default: bool = false,

    // When deserializing, any missing fields should be filled in from the
    // object returned by the given function.
    //
    // Overrides `default`.
    //default_path: ?[]const u8 = null,

    // Always error during deserialization when encountering unknown fields.
    //
    // This attribute isn't compatible with `flatten`.
    //deny_unknown_fields: bool = false,

    // Deserialize this type by deserializing into the given type, then
    // converting.
    //from: ?[]const u8 = null,

    // Serialize this type by converting it into the specified type and
    // serializing that.
    //into: ?[]const u8 = null,

    // Serialize and deserialize this struct with the given name instead of
    // its type name.
    //rename: []const u8 = @typeName(T),
    rename: ?[]const u8 = null,

    // Rename all the fields of this struct according to the given case
    // convention.
    //rename_all: ?Case = null,

    // Use the internally tagged enum representation for this enum, with
    // the given tag.
    //tag: ?[]const u8 = null,

    // Deserialize this type by deserializing into the given type, then
    // converting fallibly.
    //try_from: ?[]const u8 = null,

    // Use the untagged enum representation for this enum.
    //untagged: bool = false,
};

const FieldAttributes = struct {
    // Deserialize this field from the given names *or* its type
    // name.
    //alias: ?[][]const u8 = null,

    // If the value is not present when deserializing, use the
    // field's default value.
    //default: bool = false,

    // If the value is not present when deserializing, call a
    // function to get a default value.
    //
    // Overrides `default`.
    //default_path: ?[]const u8 = null,

    // Deserialize this field using a function that is different
    // from the normal deserialization implementation.
    //deserialize_with: ?[]const u8 = null,

    // Flatten the contents of this field into the container it is
    // defined in.
    //
    // This attribute is not compatible with the
    // deny_unknown_fields attribute.
    //flatten: bool = false,

    // Serialize and deserialize this field with the given name
    // instead of its type name.
    rename: ?[]const u8 = null,

    // Skip this field during serialization and deserialziation.
    //
    // During deserialization, the field's default value will be
    // used.
    skip: bool = false,

    // Call a function to determine whether to skip serializing
    // this field.
    //skip_ser_if: ?[]const u8 = null,

    // Serialize this field using a function that is different from
    // the normal serialization implementation.
    //serialize_with: ?[]const u8 = null,

    // Combination of serialize_with and deserialize_with.
    //with: ?[]const u8 = null,
};

const VariantAttributes = struct {
    // Deserialize this variant from the given names *or* its type
    // name.
    //alias: ?[][]const u8 = null,

    // Deserialize this variant using a function that is different
    // from the normal deserialization implementation.
    //deserialize_with: ?[]const u8 = null,

    // Serialize and deserialize this variant with the given name
    // instead of its type name.
    rename: ?[]const u8 = null,

    // Never serialize or deserialize this variant.
    skip: bool = false,

    // Serialize this variant using a function that is different from
    // the normal serialization implementation.
    //serialize_with: ?[]const u8 = null,

    // Combination of serialize_with and deserialize_with.
    //with: ?[]const u8 = null,
};

pub const Case = enum {
    // foobar
    lower,

    // FOOBAR
    upper,

    // foo_bar
    snake,

    // fooBar
    camel,

    // Foobar
    pascal,

    // foo-bar
    kebab,

    // FOO_BAR
    screaming_snake,

    // FOO-BAR
    screaming_kebab,
};

/// Returns an attribute map type.
///
/// Generally, users won't actually call this function. It's mostly designed to
/// be used by Getty to validate anonymous struct literals, which users are
/// encouraged to use instead.
///
/// ## Parameters
///
/// - T is the type of the value being serialized.
///
/// - attributes is a struct value, whose field names must match either the
///   word "Container" or a field/variant name in the value being serialized.
///   The value of each field in attributes must be a struct. Specifically, the
///   value for any field named "Container" must be coercable to
///   ContainerAttributes type, while the value for all other fields must be
///   coercable to either the FieldAttributes or VariantAttributes type,
///   depending on whether or not the value being serialized is a struct, enum,
///   or union.
///
///   For example, the following code defines container and field attributes
///   for a Point type:
///
///     ```
///     const Point = struct {
///         x: i32,
///         y: i32,
///     };
///
///     const attributes = .{
///       .Container = .{ .rename = "Coordinate" },
///       .x = .{ .rename = "X" },
///       .y = .{ .skip = true },
///     };
///     ```
///
/// ## Return Value
///
/// The return value is a type. Specifically, a struct type with fields that
/// correspond to either:
///
///   1. Fields/variants in the struct/enum/union for which attributes are
///      being specified (in the previous example, these would be "x" and "y").
///
///   2) The struct/enum/union itself (in the previous example, this would be
///      "Container").
///
/// The returned type will only contain fields that exist in the attribute map
/// passed in to the function.
///
/// ## Examples
///
/// Consider the following code:
///
///   ```
///   const Point = struct {
///       x: i32,
///       y: i32,
///   };
///
///   const attributes = .{
///     .Container = .{ .rename = "Coordinate" },
///     .x = .{ .rename = "X" },
///     .y = .{ .skip = true },
///   };
///
///   const T = getty.Attributes(Point, attributes);
///   ```
///
/// Here, T would resolve to the following type:
///
///   ```
///   struct {
///       Container: struct {
///           rename: ?[]const u8 = null,
///           // (...) other container attributes
///       },
///       x: struct {
///           rename: ?[]const u8 = null,
///           // (...) other field attributes
///       },
///       y: struct {
///           skip: bool = false,
///           // (...) other field attributes
///       },
///   }
///   ```
pub fn Attributes(comptime T: type, comptime attributes: anytype) type {
    comptime {
        const A = @TypeOf(attributes);
        const attributes_info = @typeInfo(A);

        if (attributes_info != .Struct) {
            @compileError("unexpected attribute map type");
        }

        if (attributes_info.Struct.fields.len == 0) {
            return struct {};
        }

        const InnerAttributes = switch (@typeInfo(T)) {
            .Struct => FieldAttributes,
            .Enum, .Union => VariantAttributes,
            else => @compileError("type cannot contain attributes"),
        };
        const container = &ContainerAttributes{};
        const inner = &InnerAttributes{};

        var fields: [attributes_info.Struct.fields.len]Type.StructField = undefined;

        inline for (attributes_info.Struct.fields) |field, i| {
            if (@hasField(T, field.name)) {
                // If a field in the passed-in attribute map matches a field in the
                // passed-in value, add the inner attribute to the fields array.
                fields[i] = .{
                    .name = field.name,
                    .field_type = InnerAttributes,
                    .default_value = inner,
                    .is_comptime = false,
                    .alignment = 4,
                };
            } else if (std.mem.eql(u8, field.name, "Container")) {
                // If a field in the passed-in attribute map matches the word
                // "Container", add the container attribute to the fields array.
                fields[i] = .{
                    .name = "Container",
                    .field_type = ContainerAttributes,
                    .default_value = container,
                    .is_comptime = false,
                    .alignment = 4,
                };
            } else {
                @compileError(std.fmt.comptimePrint("invalid field: {s}", .{field.name}));
            }
        }

        return @Type(Type{
            .Struct = .{
                .layout = .Auto,
                .fields = &fields,
                .decls = &[_]Type.Declaration{},
                .is_tuple = false,
            },
        });
    }
}
