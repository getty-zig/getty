const std = @import("std");

const concepts = @import("../../lib.zig").concepts;

const concept = "getty.de.dbt";

pub fn @"getty.de.dbt"(comptime dbt: anytype) void {
    comptime {
        const T = if (@TypeOf(dbt) == type) dbt else @TypeOf(dbt);
        const info = @typeInfo(T);

        if (info == .Struct and info.Struct.is_tuple) {
            // Check each DB in the DT.
            for (std.meta.fields(T)) |field| {
                @"getty.de.dbt"(@field(dbt, field.name));
            }
        } else {
            // Check DB is a namespace.
            if (@TypeOf(dbt) != type or info != .Struct or info.Struct.is_tuple) {
                concepts.err(concept, "deserialization block is not a namespace");
            }

            // Check number of fields.
            if (info.Struct.fields.len != 0) {
                concepts.err(concept, "deserialization block contains fields");
            }

            // Check number of declarations.
            var num_decls = 0;
            for (info.Struct.decls) |decl| {
                if (decl.is_pub) {
                    num_decls += 1;
                }
            }
            if (num_decls != 2 and num_decls != 3) {
                concepts.err(concept, "deserialization block contains an unexpected number of declarations");
            }

            // Check functions.
            if (!std.meta.trait.hasFunctions(T, .{"is"})) {
                concepts.err(concept, "deserialization block missing `is` function");
            }

            switch (num_decls) {
                2 => {
                    if (!@hasDecl(T, "attributes")) {
                        concepts.err(concept, "deserialization block missing `attributes` declaration");
                    }

                    const attr_info = @typeInfo(@TypeOf(@field(T, "attributes")));
                    if (attr_info != .Struct or !attr_info.Struct.is_tuple) {
                        concepts.err(concept, "unexpected type for `attributes` declaration");
                    }
                },
                3 => {
                    if (!std.meta.trait.hasFunctions(T, .{ "deserialize", "Visitor" })) {
                        concepts.err(concept, "deserialization block missing `deserialize` and `Visitor` functions");
                    }
                },
                else => unreachable, // UNREACHABLE: we've already checked the number of declarations.
            }
        }
    }
}
