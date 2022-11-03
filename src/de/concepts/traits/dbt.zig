const std = @import("std");

pub fn is_dbt(comptime dbt: anytype) bool {
    comptime {
        const T = if (@TypeOf(dbt) == type) dbt else @TypeOf(dbt);
        const info = @typeInfo(T);

        if (info == .Struct and info.Struct.is_tuple) {
            // Check each DB in the DT.
            for (std.meta.fields(T)) |field| {
                if (!is_dbt(@field(dbt, field.name))) {
                    return false;
                }
            }
        } else {
            // Check DB is a namespace.
            if (@TypeOf(dbt) != type or info != .Struct or info.Struct.is_tuple) {
                return false;
            }

            // Check number of fields.
            if (info.Struct.fields.len != 0) {
                return false;
            }

            // Check number of declarations.
            var num_decls = 0;
            for (info.Struct.decls) |decl| {
                if (decl.is_pub) {
                    num_decls += 1;
                }
            }
            if (num_decls != 2 and num_decls != 3) {
                return false;
            }

            // Check functions.
            if (!std.meta.trait.hasFunctions(T, .{"is"})) {
                return false;
            }

            switch (num_decls) {
                2 => {
                    if (!@hasDecl(T, "attributes")) {
                        return false;
                    }

                    const attr_info = @typeInfo(@TypeOf(@field(T, "attributes")));
                    if (attr_info != .Struct or !attr_info.Struct.is_tuple) {
                        return false;
                    }
                },
                3 => {
                    if (!std.meta.trait.hasFunctions(T, .{ "deserialize", "Visitor" })) {
                        return false;
                    }
                },
                else => unreachable, // UNREACHABLE: we've already checked the number of declarations.
            }
        }

        return true;
    }
}
