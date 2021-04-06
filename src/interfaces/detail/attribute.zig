const std = @import("std");

pub const Style = enum {
    camel,
    kebab,
    lower,
    pascal,
    screaming_kebab,
    screaming_snake,
    snake,
    upper,
};

pub const Attributes = union(enum) {
    Container: union(enum) {
        All: struct {
            //bound: ,
            //content: ,
            rename: []const u8,
            rename_all: Style,
            //remote: ,
            //tag: ,
            transparent: bool,
            //untagged: ,
        },

        Serialize: struct {
            into: type,
        },

        Deserialize: struct {
            //default: ,
            deny_unknown_fields: bool,
            from: type,
            try_from: type,
        },
    },

    Field: union(enum) {
        All: struct {
            //bound: ,
            //flatten: ,
            rename: []const u8,
            skip: bool,
            with: []const u8,
        },

        Serialize: struct {
            //getter: ,
            //skip_serializing_if: fn,
        },

        Deserialize: struct {
            alias: []const u8,
            //default: ,
        },
    },

    Variant: union(enum) {
        All: struct {
            //bound: ,
            rename: []const u8,
            rename_all: Style,
            skip: bool,
            with: []const u8,
        },

        Serialize: struct {},

        Deserialize: struct {
            alias: []const u8,
            other: bool,
        },
    },
};

pub fn check_attributes(comptime T: type, attribute_map: anytype, mode: enum { Serialize, Deserialize }) void {
    // Aliases
    const assert = std.debug.assert;

    const fields = std.meta.fields;
    const TagPayload = std.meta.TagPayload;

    // Attribute map declarations
    const AttributeMap = @TypeOf(attribute_map);
    const attribute_map_info = @typeInfo(AttributeMap);

    const Container = TagPayload(Attributes, .Container);
    const ContainerAll = TagPayload(Container, .All);
    const ContainerMode = if (mode == .Serialize) TagPayload(Container, .Serialize) else TagPayload(Container, .Deserialize);

    const Field = TagPayload(Attributes, .Field);
    const FieldAll = TagPayload(Field, .All);
    const FieldMode = if (mode == .Serialize) TagPayload(Field, .Serialize) else TagPayload(Field, .Deserialize);

    const Variant = TagPayload(Attributes, .Variant);
    const VariantAll = TagPayload(Variant, .All);
    const VariantMode = if (mode == .Serialize) TagPayload(Variant, .Serialize) else TagPayload(Variant, .Deserialize);

    // Ensure that the attribute map is a struct.
    assert(attribute_map_info == .Struct);

    inline for (fields(AttributeMap)) |ident| {
        const attributes_info = @typeInfo(ident.field_type);

        // Ensure all identifiers are either in T or has the same name as T.
        assert(@hasField(T, ident.name) or std.mem.eql(u8, ident.name, @typeName(T)));

        // Ensure attribute list is a struct.
        assert(attributes_info == .Struct);

        // Ensure at least one attribute is given for each specified identifier.
        assert(attributes_info.Struct.fields.len > 0);

        // Ensure all attributes are valid.
        inline for (fields(ident.field_type)) |attribute| {
            const name = attribute.name;

            // TODO: type checks
            if (std.mem.eql(u8, ident.name, @typeName(T))) {
                assert(@hasField(ContainerAll, name) or @hasField(ContainerMode, name));
            } else switch (attribute_map_info) {
                .Struct => assert(@hasField(FieldAll, name) or @hasField(FieldMode, name)),
                .Enum => assert(@hasField(VariantAll, name) or @hasField(VariantMode, name)),
                else => unreachable,
            }
        }
    }
}
