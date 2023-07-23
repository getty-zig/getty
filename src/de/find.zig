const dt = @import("tuples.zig").dt;
const has_block = @import("../block.zig").has_block;

/// Returns the highest priority Deserialization Block for a type.
pub fn find_db(
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface type.
    comptime De: type,
) type {
    comptime {
        // Process user DBs.
        for (De.user_dt) |db| {
            if (db.is(T)) {
                return db;
            }
        }

        // Process type DBs.
        if (has_block(T, .de)) {
            return T.@"getty.db";
        }

        // Process deserializer DBs.
        for (De.deserializer_dt) |db| {
            if (db.is(T)) {
                return db;
            }
        }

        // Process default DBs.
        for (dt) |db| {
            if (db.is(T)) {
                return db;
            }
        }

        @compileError("type is not supported: " ++ @typeName(T));
    }
}
