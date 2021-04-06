# Serde

Serde is a framework for serializing and deserializing Zig data structures.

## Quick Start

```zig
const print = @import("std").debug.print;
const serde = @import("serde");

const Point = struct {
    usingnamespace serde.Serialize(@This(), .{});
    usingnamespace serde.Deserialize(@This(), .{});

    x: i32,
    y: i32,
};

pub const main = fn() !void {
    var point = Point{ .x = 1, .y = 2 };

    // Convert the Point to a JSON string.
    var serialized = try serde.json.to_str(&point);

    // Prints out {"x":1,"y":2}
    print("{}\n", .{serialized});

    // Convert the JSON string back to a Point.
    var deserialized = try serde.json.from_str(&serialized);

    // Prints out Point{ .x = 1, .y = 2 }
    print("{}\n", .{deserialized});
};
```
