const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.de.dbt";

pub fn @"getty.de.dbt"(comptime dbt: anytype) void {
    const T = if (@TypeOf(dbt) == type) dbt else @TypeOf(dbt);
    const info = @typeInfo(T);

    comptime {
        if (info == .Struct and info.Struct.is_tuple) {
            inline for (std.meta.fields(T)) |field| {
                const db = @field(dbt, field.name);

                if (@TypeOf(db) != type) {
                    concepts.err(concept, "found non-namespace Deserialization Block");
                }

                switch (@typeInfo(db)) {
                    .Struct => |db_info| {
                        if (db_info.is_tuple) {
                            concepts.err(concept, "found non-namespace Deserialization Block");
                        }

                        if (db_info.fields.len != 0) {
                            concepts.err(concept, "found field in Deserialization Block");
                        }

                        inline for (.{ "is", "deserialize", "Visitor" }) |func| {
                            if (!std.meta.trait.hasFunctions(db, .{func})) {
                                concepts.err(concept, "missing `" ++ func ++ "` function in Deserialization Block");
                            }
                        }
                    },
                    else => concepts.err(concept, "found non-namespace Deserialization Block"),
                }
            }
        } else {
            if (info != .Struct or info.Struct.is_tuple) {
                concepts.err(concept, "found non-namespace Deserialization Block");
            }

            if (info.Struct.fields.len != 0) {
                concepts.err(concept, "found field in Deserialization Block");
            }

            inline for (.{ "is", "deserialize", "Visitor" }) |func| {
                if (!std.meta.trait.hasFunctions(T, .{func})) {
                    concepts.err(concept, "missing `" ++ func ++ "` function in Deserialization Block");
                }
            }
        }
    }
}
