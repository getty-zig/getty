const std = @import("std");
const comptimePrint = std.fmt.comptimePrint;
const Type = std.builtin.Type;

/// Case conventions.
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

/// Tag representations for union variants.
pub const Tag = enum {
    external,
    internal,
    untagged,
};

/// Returns an attribute map type.
pub fn Attributes(comptime T: type, comptime attributes: anytype) type {
    const type_name = @typeName(T);
    const A = @TypeOf(attributes);
    const attributes_info = @typeInfo(A);

    // Check that attributes is a struct.
    if (attributes_info != .Struct) {
        @compileError(comptimePrint("expected attributes to be a struct, found `{s}`", .{@typeName(A)}));
    }

    // If attributes contains no fields, return an empty attribute map.
    if (attributes_info.Struct.fields.len == 0) {
        return struct {};
    }

    const container = &ContainerAttributes{};

    var fields: [attributes_info.Struct.fields.len]Type.StructField = undefined;

    inline for (attributes_info.Struct.fields, 0..) |field, i| {
        if (@hasField(T, field.name)) {
            for (std.meta.fields(T)) |f| {
                if (std.mem.eql(u8, field.name, f.name)) {
                    const Attrs = switch (@typeInfo(T)) {
                        .Enum => VariantAttributes,
                        .Struct => FieldAttributes(f.type),
                        .Union => VariantAttributes,
                        else => @compileError(comptimePrint("expected attributes to be defined in an enum, struct or union: found `{s}`", .{@typeName(T)})),
                    };
                    const attrs = &Attrs{};

                    // If a field in the passed-in attribute map matches a field in the
                    // passed-in value, add the inner attribute to the fields array.
                    fields[i] = .{
                        .name = field.name,
                        .type = Attrs,
                        .default_value = attrs,
                        .is_comptime = false,
                        .alignment = 4,
                    };

                    break;
                }
            }
        } else if (std.mem.eql(u8, field.name, "Container")) {
            // If a field in the passed-in attribute map matches the word
            // "Container", add the container attribute to the fields array.
            fields[i] = .{
                .name = "Container",
                .type = ContainerAttributes,
                .default_value = container,
                .is_comptime = false,
                .alignment = 4,
            };
        } else {
            @compileError(comptimePrint("nonexistent field/variant `{s}` in type `{s}`", .{ field.name, type_name }));
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

/// Checks whether `block` defines (de)serialization attributes for `T`.
pub fn has_attributes(
    /// A type to check.
    comptime T: type,
    /// A (de)serialization block.
    comptime block: type,
) bool {
    comptime {
        switch (@typeInfo(T)) {
            .Enum, .Union => {},
            .Struct => |info| if (info.is_tuple) return false,
            else => return false,
        }

        return @hasDecl(block, "attributes") and is_attributes(T, block.attributes);
    }
}

/// Checks whether `attributes` is a (de)serialization attribute list for `T`.
pub fn is_attributes(
    /// A type that `attributes` applies to.
    comptime T: type,
    /// An attribute list to check.
    attributes: anytype,
) bool {
    comptime {
        const A = Attributes(T, attributes);
        var a = A{};

        inline for (std.meta.fields(@TypeOf(attributes))) |field| {
            @field(a, field.name) = @field(attributes, field.name);
        }

        return std.meta.eql(a, attributes);
    }
}

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
    ignore_unknown_fields: bool = false,

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

    // Use the specified representation for this union.
    tag: Tag = .external,

    // Deserialize this type by deserializing into the given type, then
    // converting fallibly.
    //try_from: ?[]const u8 = null,

    // Use the untagged enum representation for this enum.
    //untagged: bool = false,
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

fn FieldAttributes(comptime Field: type) type {
    return struct {
        // Deserialize this field from the given names *or* its type
        // name.
        //alias: ?[][]const u8 = null,

        // If the value is not present when deserializing, use the
        // field's default value.
        default: ?Field = null,

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
        // This attribute is not compatible with the ignore_unknown_fields
        // attribute.
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
}
