const std = @import("std");

const concept = "getty.de.dbt";

pub fn @"getty.de.dbt"(comptime dbt: anytype) void {
    comptime {
        const DBT = @TypeOf(dbt);

        switch (DBT == type) {
            true => {
                const info = @typeInfo(dbt);

                // Check DB is a namespace.
                if (info != .Struct or info.Struct.is_tuple) {
                    @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: deserialization block is not a namespace", .{concept}));
                }

                // Check number of fields.
                if (info.Struct.fields.len != 0) {
                    @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: deserialization block contains fields", .{concept}));
                }

                // Check number of declarations.
                var num_decls = 0;
                for (info.Struct.decls) |decl| {
                    if (decl.is_pub) {
                        num_decls += 1;
                    }
                }
                if (num_decls != 2 and num_decls != 3) {
                    @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: deserialization block contains an unexpected number of declarations", .{concept}));
                }

                // Check functions.
                if (!std.meta.trait.hasFunctions(dbt, .{"is"})) {
                    @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: deserialization block missing `is` function", .{concept}));
                }

                switch (num_decls) {
                    2 => {
                        if (!@hasDecl(dbt, "attributes")) {
                            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: deserialization block missing `attributes` declaration", .{concept}));
                        }

                        const attr_info = @typeInfo(@TypeOf(@field(dbt, "attributes")));
                        if (attr_info != .Struct or attr_info.Struct.is_tuple) {
                            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: unexpected type for `attributes` declaration", .{concept}));
                        }
                    },
                    3 => {
                        if (!std.meta.trait.hasFunctions(dbt, .{ "deserialize", "Visitor" })) {
                            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: deserialization block missing `deserialize` and `Visitor` functions", .{concept}));
                        }
                    },
                    else => unreachable, // UNREACHABLE: we've already checked the number of declarations.
                }
            },
            false => {
                const info = @typeInfo(DBT);

                // Check that the DT is a tuple.
                if (info == .Struct and info.Struct.is_tuple) {
                    // Check each DB in the DT.
                    for (std.meta.fields(DBT)) |field| {
                        @"getty.de.dbt"(@field(dbt, field.name));
                    }
                } else {
                    // Check that the DT contains only types.
                    return false;
                }
            },
        }
    }
}
