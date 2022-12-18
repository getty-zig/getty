const std = @import("std");

/// Checks to see if a type `T` contains a type-defined serialization block.
pub fn has_sb(
    /// A type containing a serialization block.
    comptime T: type,
) bool {
    comptime {
        return std.meta.trait.isContainer(T) and @hasDecl(T, "getty.sb") and is_tsb(T.@"getty.sb");
    }
}

/// Validates a serialization block or tuple.
pub fn is_sbt(
    /// A serialization block or tuple.
    comptime sbt: anytype,
) bool {
    comptime {
        const SBT = @TypeOf(sbt);

        if (SBT == @TypeOf(null)) {
            return true;
        }

        if (SBT == type) {
            const info = @typeInfo(sbt);

            // Check SB is a namespace.
            if (info != .Struct or info.Struct.is_tuple) {
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
            if (num_decls != 2) {
                return false;
            }

            // Check functions.
            //
            // We've already checked that there are only two declarations, so
            // we don't need to check that only `serialize` or `attributes` is
            // declared. Checking that either one of them exists is good enough
            // as the other declaration must be `is`.
            if (!std.meta.trait.hasFunctions(sbt, .{"is"})) {
                return false;
            }

            if (!std.meta.trait.hasFunctions(sbt, .{"serialize"}) and !@hasDecl(sbt, "attributes")) {
                return false;
            }

            // These are just some preliminary attribute checks. The real
            // checks are done just before Getty serializes the value.
            if (@hasDecl(sbt, "attributes")) {
                const attr_info = @typeInfo(@TypeOf(sbt.attributes));

                // Check that the attributes declaration is a struct (or an empty tuple).
                if (attr_info != .Struct or (attr_info.Struct.is_tuple and sbt.attributes.len != 0)) {
                    return false;
                }
            }
        } else {
            const info = @typeInfo(SBT);

            // Check that the ST is a tuple.
            if (info == .Struct and info.Struct.is_tuple) {
                // Check each SB in the ST.
                for (std.meta.fields(SBT)) |field| {
                    if (!is_sbt(@field(sbt, field.name))) {
                        return false;
                    }
                }
            } else {
                return false;
            }
        }

        return true;
    }
}

test "is_sbt (SB)" {
    // Not a type.
    try std.testing.expect(!is_sbt(1));
    try std.testing.expect(!is_sbt("foo"));
    try std.testing.expect(!is_sbt(.{ 1, 2, 3 }));
    try std.testing.expect(!is_sbt(.{ .x = 1, .serialize = 2 }));

    // Not a POD struct type.
    try std.testing.expect(!is_sbt(i32));
    try std.testing.expect(!is_sbt([]u8));
    try std.testing.expect(!is_sbt(*struct {}));
    try std.testing.expect(!is_sbt(std.meta.Tuple(&.{ i32, i32 })));

    // Non-zero number of fields.
    try std.testing.expect(!is_sbt(struct { x: i32 }));
    try std.testing.expect(!is_sbt(struct { x: i32, y: i32 }));

    // Incorrect number of declarations.
    try std.testing.expect(!is_sbt(struct {
        pub const x: i32 = 0;
    }));

    try std.testing.expect(!is_sbt(struct {
        pub fn foo() void {
            unreachable;
        }
    }));

    try std.testing.expect(!is_sbt(struct {
        pub fn is() void {
            unreachable;
        }

        pub fn serialize() void {
            unreachable;
        }

        pub const attributes = .{};
    }));

    // Incorrect functions.
    try std.testing.expect(!is_sbt(struct {
        pub fn foo() void {
            unreachable;
        }

        pub fn bar() void {
            unreachable;
        }
    }));

    // Empty attributes.
    try std.testing.expect(is_sbt(struct {
        pub fn is() void {
            unreachable;
        }

        pub const attributes = .{};
    }));

    // Success
    try std.testing.expect(is_sbt(struct {
        pub fn is() void {
            unreachable;
        }

        pub fn serialize() void {
            unreachable;
        }
    }));

    try std.testing.expect(is_sbt(struct {
        pub fn is() void {
            unreachable;
        }

        pub const attributes = .{ .x = 1, .y = 2 };
    }));
}

test "is_sbt (ST)" {
    // Not a type.
    try std.testing.expect(!is_sbt(.{1}));
    try std.testing.expect(!is_sbt(.{"foo"}));
    try std.testing.expect(!is_sbt(.{.{ 1, 2, 3 }}));
    try std.testing.expect(!is_sbt(.{.{ .x = 1, .serialize = 2 }}));

    // Not a POD struct type.
    try std.testing.expect(!is_sbt(.{i32}));
    try std.testing.expect(!is_sbt(.{[]u8}));
    try std.testing.expect(!is_sbt(.{*struct {}}));
    try std.testing.expect(!is_sbt(.{std.meta.Tuple(&.{ i32, i32 })}));

    // Non-zero number of fields.
    try std.testing.expect(!is_sbt(.{struct { x: i32 }}));
    try std.testing.expect(!is_sbt(.{struct { x: i32, y: i32 }}));

    // Incorrect number of declarations.
    try std.testing.expect(!is_sbt(.{struct {
        pub const x: i32 = 0;
    }}));

    try std.testing.expect(!is_sbt(.{struct {
        pub fn foo() void {
            unreachable;
        }
    }}));

    try std.testing.expect(!is_sbt(.{struct {
        pub fn is() void {
            unreachable;
        }

        pub fn serialize() void {
            unreachable;
        }

        pub const attributes = .{};
    }}));

    // Incorrect functions.
    try std.testing.expect(!is_sbt(.{struct {
        pub fn foo() void {
            unreachable;
        }

        pub fn bar() void {
            unreachable;
        }
    }}));

    // Empty attributes.
    try std.testing.expect(is_sbt(.{struct {
        pub fn is() void {
            unreachable;
        }

        pub const attributes = .{};
    }}));

    // Success
    try std.testing.expect(is_sbt(.{}));

    try std.testing.expect(is_sbt(.{struct {
        pub fn is() void {
            unreachable;
        }

        pub fn serialize() void {
            unreachable;
        }
    }}));

    try std.testing.expect(is_sbt(.{struct {
        pub fn is() void {
            unreachable;
        }

        pub const attributes = .{ .x = 1, .y = 2 };
    }}));
}

/// Validates a type-defined serialization block.
pub fn is_tsb(
    /// A type-defined serialization block.
    comptime sb: anytype,
) bool {
    comptime {
        const SB = @TypeOf(sb);

        if (SB != type) {
            return false;
        }

        const info = @typeInfo(sb);

        // Check SB is a namespace.
        if (info != .Struct or info.Struct.is_tuple) {
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
        if (num_decls != 1) {
            return false;
        }

        // Check declarations.
        if (!std.meta.trait.hasFunctions(sb, .{"serialize"}) and !@hasDecl(sb, "attributes")) {
            return false;
        }

        // These are just some preliminary attribute checks. The real
        // checks are done just before Getty serializes the value.
        if (@hasDecl(sb, "attributes")) {
            const attr_info = @typeInfo(@TypeOf(sb.attributes));

            // Check that the attributes declaration is a struct (or an empty tuple).
            if (attr_info != .Struct or (attr_info.Struct.is_tuple and sb.attributes.len != 0)) {
                return false;
            }
        }

        return true;
    }
}

test "is_tsb" {
    // Not a type.
    try std.testing.expect(!is_tsb(1));
    try std.testing.expect(!is_tsb("foo"));
    try std.testing.expect(!is_tsb(.{ 1, 2, 3 }));
    try std.testing.expect(!is_tsb(.{ .x = 1, .serialize = 2 }));

    // Not a POD struct type.
    try std.testing.expect(!is_tsb(i32));
    try std.testing.expect(!is_tsb([]u8));
    try std.testing.expect(!is_tsb(*struct {}));
    try std.testing.expect(!is_tsb(std.meta.Tuple(&.{ i32, i32 })));

    // Non-zero number of fields.
    try std.testing.expect(!is_tsb(struct { x: i32 }));
    try std.testing.expect(!is_tsb(struct { x: i32, y: i32 }));

    // Incorrect number of declarations.
    try std.testing.expect(!is_tsb(struct {
        pub const x: i32 = 0;
    }));

    try std.testing.expect(!is_tsb(struct {
        pub fn foo() void {
            unreachable;
        }
    }));

    try std.testing.expect(!is_tsb(struct {
        pub fn is() void {
            unreachable;
        }

        pub fn serialize() void {
            unreachable;
        }

        pub const attributes = .{};
    }));

    try std.testing.expect(!is_tsb(struct {
        pub fn is() void {
            unreachable;
        }

        pub fn serialize() void {
            unreachable;
        }
    }));

    try std.testing.expect(!is_tsb(struct {
        pub fn is() void {
            unreachable;
        }

        pub const attributes = .{};
    }));

    // Incorrect declarations.
    try std.testing.expect(!is_tsb(struct {
        pub fn foo() void {
            unreachable;
        }

        pub fn bar() void {
            unreachable;
        }
    }));

    try std.testing.expect(!is_tsb(struct {
        pub fn is() void {
            unreachable;
        }
    }));

    // Success
    try std.testing.expect(is_tsb(struct {
        pub fn serialize() void {
            unreachable;
        }
    }));

    try std.testing.expect(is_tsb(struct {
        pub const attributes = .{};
    }));

    try std.testing.expect(is_tsb(struct {
        pub const attributes = .{ .x = 1, .y = 2 };
    }));
}
