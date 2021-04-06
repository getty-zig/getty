const std = @import("std");

pub const RenameStyle = enum {
    camel,
    kebab,
    lower,
    pascal,
    screaming_kebab,
    screaming_snake,
    snake,
    upper,
};

pub const Attributes = struct {
    const Container = struct {
        const Ser = struct {
            //bound: ,
            //content: ,
            into: type,
            rename: []const u8,
            rename_all: RenameStyle,
            //remote: ,
            //tag: ,
            transparent: bool,
            //untagged: ,
        };

        const De = struct {
            //bound: ,
            //content: ,
            //default: ,
            deny_unknown_fields: bool,
            from: type,
            into: type,
            rename: []const u8,
            rename_all: RenameStyle,
            //remote: ,
            //tag: ,
            transparent: bool,
            try_from: type,
            //untagged: ,
        };
    };

    const Field = struct {
        const Ser = struct {
            //bound: ,
            //flatten: ,
            //getter: ,
            rename: []const u8,
            skip: bool,
            //skip_serializing_if: fn,
            with: []const u8,
        };

        const De = struct {
            alias: []const u8,
            //bound: ,
            //default: ,
            //flatten: ,
            rename: []const u8,
            skip: bool,
            with: []const u8,
        };
    };

    const Variant = struct {
        const Ser = struct {
            //bound: ,
            rename: []const u8,
            rename_all: RenameStyle,
            skip: bool,
            with: []const u8,
        };

        const De = struct {
            alias: []const u8,
            //bound: ,
            other: bool,
            rename: []const u8,
            rename_all: RenameStyle,
            skip: bool,
            with: []const u8,
        };
    };
};

pub fn check_attributes(comptime T: type, attr_map: anytype, mode: enum { Ser, De }) void {
    // Ensure attribute map is a struct.
    std.debug.assert(@typeInfo(@TypeOf(attr_map)) == .Struct);

    inline for (std.meta.fields(@TypeOf(attr_map))) |id| {
        // Ensure the identifier is either a field/variant name in T or has the same name as T.
        std.debug.assert(@hasField(T, id.name) or std.mem.eql(u8, id.name, @typeName(T)));

        // Ensure the attribute list is a struct with at least one attribute.
        std.debug.assert(@typeInfo(id.field_type) == .Struct and @typeInfo(id.field_type).Struct.fields.len > 0);

        inline for (std.meta.fields(id.field_type)) |attr| {
            const AttrType = if (std.mem.eql(u8, id.name, @typeName(T))) Attributes.Container else switch (@typeInfo(T)) {
                .Struct => Attributes.Field,
                .Enum => Attributes.Variant,
                else => unreachable,
            };

            // Ensure the attribute name is in the corresponding `Attribute` struct.
            std.debug.assert(@hasField(@field(AttrType, @tagName(mode)), attr.name));
        }
    }
}
