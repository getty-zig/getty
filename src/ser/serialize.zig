const std = @import("std");

const meta = std.meta;
const trait = meta.trait;

/// Serializes values that are of a type supported by Getty.
pub fn serialize(serializer: anytype, value: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    const T = @TypeOf(value);

    if (comptime match("std.array_list.ArrayList", @typeName(T))) {
        return try serialize(serializer, value.items);
    }

    if (comptime match("std.hash_map.HashMap", @typeName(T))) {
        const st = (try serializer.serializeMap(value.count())).map();
        {
            var iterator = value.iterator();
            while (iterator.next()) |entry| {
                try st.serializeEntry(entry.key_ptr.*, entry.value_ptr.*);
            }
        }
        return try st.end();
    }

    switch (@typeInfo(T)) {
        .Array => {
            const seq = (try serializer.serializeSequence(value.len)).sequence();
            for (value) |elem| {
                try seq.serializeElement(elem);
            }
            return try seq.end();
        },
        .Bool => {
            return try serializer.serializeBool(value);
        },
        .Enum, .EnumLiteral => {
            try serializer.serializeVariant(value);
        },
        .ErrorSet => {
            return try serialize(serializer, @as([]const u8, @errorName(value)));
        },
        .Float, .ComptimeFloat => {
            return try serializer.serializeFloat(value);
        },
        .Int, .ComptimeInt => {
            return try serializer.serializeInt(value);
        },
        .Null => {
            return try serializer.serializeNull();
        },
        .Optional => {
            return if (value) |v| try serialize(serializer, v) else try serialize(serializer, null);
        },
        .Pointer => |info| {
            return switch (info.size) {
                .One => switch (@typeInfo(info.child)) {
                    .Array => try serialize(serializer, @as([]const meta.Elem(info.child), value)),
                    else => try serialize(serializer, value.*),
                },
                .Slice => blk: {
                    if (comptime trait.isZigString(T)) {
                        break :blk try serializer.serializeString(value);
                    } else {
                        var seq = (try serializer.serializeSequence(value.len)).sequence();
                        for (value) |elem| {
                            try seq.serializeElement(elem);
                        }
                        return try seq.end();
                    }
                },
                else => @compileError("type `" ++ @typeName(T) ++ "` is not supported"),
            };
        },
        .Struct => |info| {
            switch (info.is_tuple) {
                true => {
                    const tuple = (try serializer.serializeTuple(meta.fields(T).len)).tuple();
                    inline for (info.fields) |field| {
                        try tuple.serializeElement(@field(value, field.name));
                    }
                    return try tuple.end();
                },
                false => {
                    const st = (try serializer.serializeStruct(@typeName(T), meta.fields(T).len)).structure();
                    inline for (info.fields) |field| {
                        try st.serializeField(field.name, @field(value, field.name));
                    }
                    return try st.end();
                },
            }
        },
        .Union => |info| {
            if (info.tag_type) |Tag| {
                inline for (info.fields) |field| {
                    if (@field(Tag, field.name) == value) {
                        return try serialize(serializer, @field(value, field.name));
                    }
                }

                // UNREACHABLE: Since we go over every field in the union, we
                // always find the field that matches the passed-in value.
                unreachable;
            } else {
                @compileError("type `" ++ @typeName(T) ++ "` is not supported");
            }
        },
        .Vector => |info| {
            return try serialize(serializer, @as([info.len]info.child, value));
        },
        else => @compileError("type `" ++ @typeName(T) ++ "` is not supported"),
    }
}

fn match(comptime expected: []const u8, comptime actual: []const u8) bool {
    if (actual.len >= expected.len and std.mem.eql(u8, actual[0..expected.len], expected)) {
        return true;
    }

    return false;
}
