const Attributes = @import("getty").Attributes;

test "Serialize - basic (struct)" {
    const Point = struct {
        usingnamespace Attributes(@This(), .{});

        x: i32,
        y: i32,
    };
}

test "Serialize - with container attribute (struct)" {
    const Point = struct {
        usingnamespace Attributes(@This(), .{
            .Container = .{ .rename = "A" },
        });

        x: i32,
        y: i32,
    };
}

test "Serialize - with field attribute (struct)" {
    const Point = struct {
        usingnamespace Attributes(@This(), .{
            .x = .{ .rename = "a" },
        });

        x: i32,
        y: i32,
    };
}
