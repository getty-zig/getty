const std = @import("std");

const ser = @import("../../ser.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Struct and !@typeInfo(T).Struct.is_tuple;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);
    const fields = std.meta.fields(T);
    const attributes = comptime ser.ser.getAttributes(T, @TypeOf(serializer));

    var s = try serializer.serializeStruct(@typeName(T), fields.len);
    const st = s.structure();

    inline for (fields) |field| {
        if (field.field_type != void) {
            // The name of the field to be deserialized.
            comptime var name: []const u8 = field.name;

            // Process attributes.
            if (attributes) |attrs| {
                if (@hasField(@TypeOf(attrs), field.name)) {
                    const attr = @field(attrs, field.name);

                    if (@hasField(@TypeOf(attr), "skip") and attr.skip) {
                        continue;
                    }

                    if (@hasField(@TypeOf(attr), "rename")) {
                        name = attr.rename;
                    }
                }
            }

            // Serialize field.
            try st.serializeField(name, @field(value, field.name));
        }
    }

    return try st.end();
}
