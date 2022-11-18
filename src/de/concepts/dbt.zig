//! Compile-time type restraint for implementations of getty.de.dbt.

const std = @import("std");

const concept = "getty.de.dbt";

pub fn @"getty.de.dbt"(comptime dbt: anytype) void {
    comptime {
        const DBT = @TypeOf(dbt);
        const type_name = if (DBT == type) @typeName(dbt) else @typeName(DBT);

        if (DBT == @TypeOf(null)) {
            return;
        }

        if (DBT == type) {
            const info = @typeInfo(dbt);

            // Check DB is a namespace.
            if (info != .Struct or info.Struct.is_tuple) {
                @compileError(std.fmt.comptimePrint("deserialization block is not a struct: {s}", .{type_name}));
            }

            // Check number of fields.
            if (info.Struct.fields.len != 0) {
                @compileError(std.fmt.comptimePrint("deserialization block contains fields: {s}", .{type_name}));
            }

            // Check number of declarations.
            var num_decls = 0;
            for (info.Struct.decls) |decl| {
                if (decl.is_pub) {
                    num_decls += 1;
                }
            }
            if (num_decls != 2 and num_decls != 3) {
                @compileError(std.fmt.comptimePrint("deserialization block contains an unexpected number of declarations: {s}", .{type_name}));
            }

            // Check functions.
            if (!std.meta.trait.hasFunctions(dbt, .{"is"})) {
                @compileError(std.fmt.comptimePrint("deserialization block is missing `is` function: {s}", .{type_name}));
            }

            switch (num_decls) {
                2 => {
                    // These are just some preliminary attribute checks. The real
                    // checks are done just before Getty serializes the value.

                    // Check that an attributes declaration exists.
                    if (!@hasDecl(dbt, "attributes")) {
                        @compileError(std.fmt.comptimePrint("deserialization block is missing an `attributes` declaration: {s}", .{type_name}));
                    }

                    // Check that the attributes declaration is a struct.
                    const attr_info = @typeInfo(@TypeOf(dbt.attributes));
                    if (attr_info != .Struct or (attr_info.Struct.is_tuple and dbt.attributes.len != 0)) {
                        @compileError(std.fmt.comptimePrint("deserialization block contains non-struct `attributes` declaration: {s}", .{@typeName(@TypeOf(dbt.attributes))}));
                    }
                },
                3 => {
                    if (!std.meta.trait.hasFunctions(dbt, .{"deserialize"})) {
                        @compileError(std.fmt.comptimePrint("deserialization block is missing `deserialize` function: {s}", .{type_name}));
                    }

                    if (!std.meta.trait.hasFunctions(dbt, .{"Visitor"})) {
                        @compileError(std.fmt.comptimePrint("deserialization block is missing `Visitor` function: {s}", .{type_name}));
                    }
                },
                else => unreachable, // UNREACHABLE: we've already checked the number of declarations.
            }
        } else {
            const info = @typeInfo(DBT);

            // Check that the DT is a tuple.
            if (info == .Struct and info.Struct.is_tuple) {
                // Check each DB in the DT.
                for (std.meta.fields(DBT)) |field| {
                    @"getty.de.dbt"(@field(dbt, field.name));
                }
            } else {
                @compileError(std.fmt.comptimePrint("expected deserialization block/tuple, found {s}", .{type_name}));
            }
        }
    }
}
