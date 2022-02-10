const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.ser.sbt";

pub fn @"getty.ser.sbt"(comptime sbt: anytype) void {
    const T = if (@TypeOf(sbt) == type) sbt else @TypeOf(sbt);
    const info = @typeInfo(T);

    comptime {
        if (info == .Struct and info.Struct.is_tuple) {
            inline for (std.meta.fields(T)) |field| {
                const sb = @field(sbt, field.name);

                if (@TypeOf(sb) != type) {
                    concepts.err(concept, "found non-namespace Serialization Block");
                }

                switch (@typeInfo(sb)) {
                    .Struct => |sb_info| {
                        if (sb_info.is_tuple) {
                            concepts.err(concept, "found non-namespace Serialization Block");
                        }

                        if (sb_info.fields.len != 0) {
                            concepts.err(concept, "found field in Serialization Block");
                        }

                        inline for (.{ "is", "serialize" }) |func| {
                            if (!std.meta.trait.hasFunctions(sb, .{func})) {
                                concepts.err(concept, "missing `" ++ func ++ "` function in Serialization Block");
                            }
                        }
                    },
                    else => concepts.err(concept, "found non-namespace Serialization Block"),
                }
            }
        } else {
            if (info != .Struct or info.Struct.is_tuple) {
                concepts.err(concept, "found non-namespace Serialization Block");
            }

            if (info.Struct.fields.len != 0) {
                concepts.err(concept, "found field in Serialization Block");
            }

            inline for (.{ "is", "serialize" }) |func| {
                if (!std.meta.trait.hasFunctions(T, .{func})) {
                    concepts.err(concept, "missing `" ++ func ++ "` function in Serialization Block");
                }
            }
        }
    }
}
