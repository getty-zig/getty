const std = @import("std");

/// Checks whether `T` contains a deserialization block.
pub fn has_db(
    /// A type to check.
    comptime T: type,
) bool {
    comptime {
        const is_enum = @typeInfo(T) == .Enum;
        const is_struct = @typeInfo(T) == .Struct and !@typeInfo(T).Struct.is_tuple;
        const is_union = @typeInfo(T) == .Union;

        return (is_enum or is_struct or is_union) and @hasDecl(T, "getty.db") and is_tdb(T.@"getty.db");
    }
}

/// Checks if `dbt` is a deserialization block or tuple.
pub fn is_dbt(
    /// An optional type or value to check.
    comptime dbt: anytype,
) bool {
    comptime {
        const DBT = @TypeOf(dbt);

        if (DBT == @TypeOf(null)) {
            return true;
        }

        if (DBT == type) {
            const info = @typeInfo(dbt);

            // Check DB is a namespace.
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
            if (num_decls != 2 and num_decls != 3) {
                return false;
            }

            // Check functions.
            if (!std.meta.trait.hasFunctions(dbt, .{"is"})) {
                return false;
            }

            switch (num_decls) {
                2 => {
                    // These are just some preliminary attribute checks. The real
                    // checks are done just before Getty serializes the value.

                    // Check that an attributes declaration exists.
                    if (!@hasDecl(dbt, "attributes")) {
                        return false;
                    }

                    // Check that the attributes declaration is a struct.
                    const attr_info = @typeInfo(@TypeOf(dbt.attributes));
                    if (attr_info != .Struct or (attr_info.Struct.is_tuple and dbt.attributes.len != 0)) {
                        return false;
                    }
                },
                3 => {
                    if (!std.meta.trait.hasFunctions(dbt, .{"deserialize"})) {
                        return false;
                    }

                    if (!std.meta.trait.hasFunctions(dbt, .{"Visitor"})) {
                        return false;
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
                    if (!is_dbt(@field(dbt, field.name))) {
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

test "is_dbt (DB)" {
    // Not a type.
    try std.testing.expect(!is_dbt(1));
    try std.testing.expect(!is_dbt("foo"));
    try std.testing.expect(!is_dbt(.{ 1, 2, 3 }));
    try std.testing.expect(!is_dbt(.{ .x = 1, .serialize = 2 }));

    // Not a POD struct type.
    try std.testing.expect(!is_dbt(i32));
    try std.testing.expect(!is_dbt([]u8));
    try std.testing.expect(!is_dbt(*struct {}));
    try std.testing.expect(!is_dbt(std.meta.Tuple(&.{ i32, i32 })));

    // Non-zero number of fields.
    try std.testing.expect(!is_dbt(struct { x: i32 }));
    try std.testing.expect(!is_dbt(struct { x: i32, y: i32 }));

    // Incorrect number of declarations.
    try std.testing.expect(!is_dbt(struct {
        pub const x: i32 = 0;
    }));

    try std.testing.expect(!is_dbt(struct {
        pub fn foo() void {
            unreachable;
        }
    }));

    try std.testing.expect(!is_dbt(struct {
        pub fn is() void {
            unreachable;
        }

        pub fn deserialize() void {
            unreachable;
        }

        pub const attributes = .{};
    }));

    // Empty attributes.
    try std.testing.expect(is_dbt(struct {
        pub fn is() void {
            unreachable;
        }

        pub const attributes = .{};
    }));

    // Success
    try std.testing.expect(is_dbt(struct {
        pub fn is() void {
            unreachable;
        }

        pub fn deserialize() void {
            unreachable;
        }

        pub fn Visitor() void {
            unreachable;
        }
    }));

    try std.testing.expect(is_dbt(struct {
        pub fn is() void {
            unreachable;
        }

        pub const attributes = .{ .x = 1, .y = 2 };
    }));
}

test "is_dbt (DT)" {
    // Not a type.
    try std.testing.expect(!is_dbt(.{1}));
    try std.testing.expect(!is_dbt(.{"foo"}));
    try std.testing.expect(!is_dbt(.{.{ 1, 2, 3 }}));
    try std.testing.expect(!is_dbt(.{.{ .x = 1, .serialize = 2 }}));

    // Not a POD struct type.
    try std.testing.expect(!is_dbt(.{i32}));
    try std.testing.expect(!is_dbt(.{[]u8}));
    try std.testing.expect(!is_dbt(.{*struct {}}));
    try std.testing.expect(!is_dbt(.{std.meta.Tuple(&.{ i32, i32 })}));

    // Non-zero number of fields.
    try std.testing.expect(!is_dbt(.{struct { x: i32 }}));
    try std.testing.expect(!is_dbt(.{struct { x: i32, y: i32 }}));

    // Incorrect number of declarations.
    try std.testing.expect(!is_dbt(.{struct {
        pub const x: i32 = 0;
    }}));

    try std.testing.expect(!is_dbt(.{struct {
        pub fn foo() void {
            unreachable;
        }
    }}));

    try std.testing.expect(!is_dbt(.{struct {
        pub fn is() void {
            unreachable;
        }

        pub fn deserialize() void {
            unreachable;
        }

        pub const attributes = .{};
    }}));

    // Empty attributes.
    try std.testing.expect(is_dbt(struct {
        pub fn is() void {
            unreachable;
        }

        pub const attributes = .{};
    }));

    // Success
    try std.testing.expect(is_dbt(.{}));

    try std.testing.expect(is_dbt(.{struct {
        pub fn is() void {
            unreachable;
        }

        pub fn deserialize() void {
            unreachable;
        }

        pub fn Visitor() void {
            unreachable;
        }
    }}));

    try std.testing.expect(is_dbt(.{struct {
        pub fn is() void {
            unreachable;
        }

        pub const attributes = .{ .x = 1, .y = 2 };
    }}));
}

/// Validates a type-defined deserialization block.
pub fn is_tdb(
    /// A type-defined deserialization block.
    comptime db: anytype,
) bool {
    comptime {
        const DB = @TypeOf(db);

        if (DB != type) {
            return false;
        }

        const info = @typeInfo(db);

        // Check DB is a namespace.
        if (info != .Struct or info.Struct.is_tuple) {
            return false;
        }

        // Check number of fields.
        if (info.Struct.fields.len != 0) {
            return false;
        }

        // Check declarations.
        var num_decls = 0;
        for (info.Struct.decls) |decl| {
            if (decl.is_pub) {
                num_decls += 1;
            }
        }

        switch (num_decls) {
            1 => {
                // These are just some preliminary attribute checks. The real
                // checks are done just before Getty serializes the value.

                // Check that an attributes declaration exists.
                if (!@hasDecl(db, "attributes")) {
                    return false;
                }

                // Check that the attributes declaration is a struct.
                const attr_info = @typeInfo(@TypeOf(db.attributes));
                if (attr_info != .Struct or (attr_info.Struct.is_tuple and db.attributes.len != 0)) {
                    return false;
                }
            },
            2 => {
                if (!std.meta.trait.hasFunctions(db, .{"deserialize"})) {
                    return false;
                }

                if (!std.meta.trait.hasFunctions(db, .{"Visitor"})) {
                    return false;
                }
            },
            else => return false,
        }

        return true;
    }
}

test "is_tdb" {
    // Not a type.
    try std.testing.expect(!is_tdb(1));
    try std.testing.expect(!is_tdb("foo"));
    try std.testing.expect(!is_tdb(.{ 1, 2, 3 }));
    try std.testing.expect(!is_tdb(.{ .x = 1, .serialize = 2 }));

    // Not a POD struct type.
    try std.testing.expect(!is_tdb(i32));
    try std.testing.expect(!is_tdb([]u8));
    try std.testing.expect(!is_tdb(*struct {}));
    try std.testing.expect(!is_tdb(std.meta.Tuple(&.{ i32, i32 })));

    // Non-zero number of fields.
    try std.testing.expect(!is_tdb(struct { x: i32 }));
    try std.testing.expect(!is_tdb(struct { x: i32, y: i32 }));

    // Incorrect declarations.
    try std.testing.expect(!is_tdb(struct {
        pub const x: i32 = 0;
    }));

    try std.testing.expect(!is_tdb(struct {
        pub fn foo() void {
            unreachable;
        }
    }));

    try std.testing.expect(!is_tdb(struct {
        pub fn is() void {
            unreachable;
        }

        pub fn deserialize() void {
            unreachable;
        }

        pub const attributes = .{};
    }));

    // Success
    try std.testing.expect(is_tdb(struct {
        pub fn deserialize() void {
            unreachable;
        }

        pub fn Visitor() void {
            unreachable;
        }
    }));

    try std.testing.expect(is_tdb(struct {
        pub const attributes = .{};
    }));

    try std.testing.expect(is_tdb(struct {
        pub const attributes = .{ .x = 1, .y = 2 };
    }));
}
