const std = @import("std");

pub fn is_dbt(comptime dbt: anytype) bool {
    const T = if (@TypeOf(dbt) == type) dbt else @TypeOf(dbt);
    const info = @typeInfo(T);

    comptime {
        if (info == .Struct and info.Struct.is_tuple) {
            // The DBT is a tuple.

            inline for (std.meta.fields(T)) |field| {
                const db = @field(dbt, field.name);

                if (@TypeOf(db) != type) {
                    // The DBT contains unexpected values (i.e., not types).
                    return false;
                }

                switch (@typeInfo(db)) {
                    .Struct => |db_info| {
                        if (db_info.is_tuple) {
                            // The DBT contains structs, but they are tuples.
                            return false;
                        }

                        if (db_info.fields.len != 0) {
                            // The DBT contains structs, but they are not namespaces.
                            return false;
                        }

                        inline for (.{ "is", "deserialize", "Visitor" }) |func| {
                            if (!std.meta.trait.hasFunctions(db, .{func})) {
                                // The DBT contains structs, but they do not have the correct functions.
                                return false;
                            }
                        }
                    },
                    else => return false, // The DBT does not contain structs.
                }
            }
        } else {
            // The DBT is not a tuple.

            if (info != .Struct or info.Struct.is_tuple) {
                // The DBT is not a struct.
                return false;
            }

            if (info.Struct.fields.len != 0) {
                // The DBT is not a struct namespace.
                return false;
            }

            inline for (.{ "is", "deserialize", "Visitor" }) |func| {
                if (!std.meta.trait.hasFunctions(T, .{func})) {
                    // The DBT does not have the correct functions.
                    return false;
                }
            }
        }

        return true;
    }
}
