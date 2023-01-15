const std = @import("std");

const concept = "getty.ser.sbt";

/// Specifies that a type is a serialization block or tuple.
pub fn @"getty.ser.sbt"(
    /// An optional type or value to check.
    comptime sbt: anytype,
) void {
    comptime {
        const SBT = @TypeOf(sbt);
        const type_name = if (SBT == type) @typeName(sbt) else @typeName(SBT);

        if (SBT == @TypeOf(null)) {
            return;
        }

        if (SBT == type) {
            const info = @typeInfo(sbt);

            // Check SB is a namespace.
            if (info != .Struct or info.Struct.is_tuple) {
                @compileError("serialization block is not a struct: " ++ type_name);
            }

            // Check number of fields.
            if (info.Struct.fields.len != 0) {
                @compileError("serialization block contains fields: " ++ type_name);
            }

            // Check number of declarations.
            var num_decls = 0;
            for (info.Struct.decls) |decl| {
                if (decl.is_pub) {
                    num_decls += 1;
                }
            }
            if (num_decls != 2) {
                @compileError("serialization block contains an unexpected number of declarations: " ++ type_name);
            }

            // Check functions.
            //
            // We've already checked that there are only two declarations, so
            // we don't need to check that only `serialize` or `attributes` is
            // declared. Checking that either one of them exists is good enough
            // as the other declaration must be `is`.
            if (!std.meta.trait.hasFunctions(sbt, .{"is"})) {
                @compileError("serialization block is missing `is` function: " ++ type_name);
            }

            if (!std.meta.trait.hasFunctions(sbt, .{"serialize"}) and !@hasDecl(sbt, "attributes")) {
                @compileError("serialization block is missing a `serialize` function or `attributes` declaration: " ++ type_name);
            }

            // These are just some preliminary attribute checks. The real
            // checks are done just before Getty serializes the value.
            if (@hasDecl(sbt, "attributes")) {
                const attr_info = @typeInfo(@TypeOf(sbt.attributes));

                // Check that the attributes declaration is a struct (or an empty tuple).
                if (attr_info != .Struct or (attr_info.Struct.is_tuple and sbt.attributes.len != 0)) {
                    @compileError("serialization block contains non-struct `attributes` declaration: " ++ @typeName(@TypeOf(sbt.attributes)));
                }
            }
        } else {
            const info = @typeInfo(SBT);

            // Check that the ST is a tuple.
            if (info == .Struct and info.Struct.is_tuple) {
                // Check each SB in the ST.
                for (std.meta.fields(SBT)) |field| {
                    @"getty.ser.sbt"(@field(sbt, field.name));
                }
            } else {
                @compileError("expected serialization block/tuple, found " ++ type_name);
            }
        }
    }
}
