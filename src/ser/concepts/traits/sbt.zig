const std = @import("std");

pub fn is_sbt(comptime sbt: anytype) bool {
    const T = if (@TypeOf(sbt) == type) sbt else @TypeOf(sbt);
    const info = @typeInfo(T);

    comptime {
        if (info == .Struct and info.Struct.is_tuple) {
            // The SBT is a tuple.

            inline for (std.meta.fields(T)) |field| {
                const sb = @field(sbt, field.name);

                if (@TypeOf(sb) != type) {
                    // The SBT contains unexpected values (i.e., not types).
                    return false;
                }

                switch (@typeInfo(sb)) {
                    .Struct => |sb_info| {
                        if (sb_info.is_tuple) {
                            // The SBT contains structs, but they are tuples.
                            return false;
                        }

                        if (sb_info.fields.len != 0) {
                            // The SBT contains structs, but they are not namespaces.
                            return false;
                        }

                        inline for (.{ "is", "serialize" }) |func| {
                            if (!std.meta.trait.hasFunctions(sb, .{func})) {
                                // The SBT contains structs, but they do not have the correct functions.
                                return false;
                            }
                        }
                    },
                    else => return false, // The SBT does not contain structs.
                }
            }
        } else {
            // The SBT is not a tuple.

            if (info != .Struct or info.Struct.is_tuple) {
                // The SBT is not a struct.
                return false;
            }

            if (info.Struct.fields.len != 0) {
                // The SBT is not a struct namespace.
                return false;
            }

            inline for (.{ "is", "serialize" }) |func| {
                if (!std.meta.trait.hasFunctions(T, .{func})) {
                    // The SBT does not have the correct functions.
                    return false;
                }
            }
        }
        return true;
    }
}
