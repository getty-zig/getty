//! Compile-time type restraint for implementations of getty.ser.sbt.

const std = @import("std");

const concept = "getty.ser.sbt";

pub fn @"getty.ser.sbt"(comptime sbt: anytype) void {
    comptime {
        const SBT = @TypeOf(sbt);

        switch (SBT == type) {
            true => {
                const info = @typeInfo(sbt);

                // Check SB is a namespace.
                if (info != .Struct or info.Struct.is_tuple) {
                    @compileError("serialization block is not a namespace");
                }

                // Check number of fields.
                if (info.Struct.fields.len != 0) {
                    @compileError("serialization block contains fields");
                }

                // Check number of declarations.
                var num_decls = 0;
                for (info.Struct.decls) |decl| {
                    if (decl.is_pub) {
                        num_decls += 1;
                    }
                }
                if (num_decls != 2) {
                    @compileError("serialization block contains an unexpected number of declarations");
                }

                // Check functions.
                //
                // We've already checked that there are only two declarations, so
                // we don't need to check that only `serialize` or `attributes` is
                // declared. Checking that either one of them exists is good enough
                // as the other declaration must be `is`.
                if (!std.meta.trait.hasFunctions(sbt, .{"is"})) {
                    @compileError("serialization block missing `is` function");
                }

                if (!std.meta.trait.hasFunctions(sbt, .{"serialize"}) and !@hasDecl(sbt, "attributes")) {
                    @compileError("serialization block must contain a `serialize` function or `attributes` declaration");
                }

                if (@hasDecl(sbt, "attributes")) {
                    // Check that the attributes declaration is a struct.
                    //
                    // These are just some prelimary checks. The real checks
                    // are done just before Getty actually serializes the
                    // value.
                    const attr_info = @typeInfo(@TypeOf(sbt.attributes));
                    if (attr_info != .Struct or attr_info.Struct.is_tuple) {
                        @compileError("unexpected type for `attributes` declaration");
                    }
                }
            },
            false => {
                const info = @typeInfo(SBT);

                // Check that the ST is a tuple.
                if (info == .Struct and info.Struct.is_tuple) {
                    // Check each SB in the ST.
                    for (std.meta.fields(SBT)) |field| {
                        @"getty.ser.sbt"(@field(sbt, field.name));
                    }
                } else {
                    @compileError("unexpected value in serialization tuple");
                }
            },
        }
    }
}
