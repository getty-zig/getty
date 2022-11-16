//! Compile-time type restraint for implementations of getty.ser.sbt.

const std = @import("std");

const concept = "getty.ser.sbt";

pub fn @"getty.ser.sbt"(comptime sbt: anytype) void {
    comptime {
        const SBT = @TypeOf(sbt);
        const type_name = if (SBT == type) @typeName(sbt) else @typeName(SBT);

        switch (SBT == type) {
            true => {
                const info = @typeInfo(sbt);

                // Check SB is a namespace.
                if (info != .Struct or info.Struct.is_tuple) {
                    @compileError(std.fmt.comptimePrint("serialization block is not a struct: {s}", .{type_name}));
                }

                // Check number of fields.
                if (info.Struct.fields.len != 0) {
                    @compileError(std.fmt.comptimePrint("serialization block contains fields: {s}", .{type_name}));
                }

                // Check number of declarations.
                var num_decls = 0;
                for (info.Struct.decls) |decl| {
                    if (decl.is_pub) {
                        num_decls += 1;
                    }
                }
                if (num_decls != 2) {
                    @compileError(std.fmt.comptimePrint("serialization block contains an unexpected number of declarations: {s}", .{type_name}));
                }

                // Check functions.
                //
                // We've already checked that there are only two declarations, so
                // we don't need to check that only `serialize` or `attributes` is
                // declared. Checking that either one of them exists is good enough
                // as the other declaration must be `is`.
                if (!std.meta.trait.hasFunctions(sbt, .{"is"})) {
                    @compileError(std.fmt.comptimePrint("serialization block is missing `is` function: {s}", .{type_name}));
                }

                if (!std.meta.trait.hasFunctions(sbt, .{"serialize"}) and !@hasDecl(sbt, "attributes")) {
                    @compileError(std.fmt.comptimePrint("serialization block is missing a `serialize` function or `attributes` declaration: {s}", .{type_name}));
                }

                // These are just some preliminary attribute checks. The real
                // checks are done just before Getty serializes the value.
                if (@hasDecl(sbt, "attributes")) {
                    const attr_info = @typeInfo(@TypeOf(sbt.attributes));

                    // Check that the attributes declaration is a struct (or an empty tuple).
                    if (attr_info != .Struct or (attr_info.Struct.is_tuple and sbt.attributes.len != 0)) {
                        @compileError(std.fmt.comptimePrint("serialization block contains non-struct `attributes` declaration: {s}", .{@typeName(@TypeOf(sbt.attributes))}));
                    }
                }
            },
            false => {
                const info = @typeInfo(SBT);

                // Check that the ST is a tuple.
                if (info == .Struct and info.Struct.is_tuple) {
                    // Check that the ST is not empty.
                    if (std.meta.fields(SBT).len == 0) {
                        @compileError(std.fmt.comptimePrint("serialization tuple is empty", .{}));
                    }

                    // Check each SB in the ST.
                    for (std.meta.fields(SBT)) |field| {
                        @"getty.ser.sbt"(@field(sbt, field.name));
                    }
                } else {
                    @compileError(std.fmt.comptimePrint("expected serialization block/tuple, found {s}", .{type_name}));
                }
            },
        }
    }
}
