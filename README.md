# Getty

Getty is a framework for serializing and deserializing Zig data structures.

## Quick Start

```zig
const print = @import("std").debug.print;
const getty = @import("getty");

const Point = struct {
    usingnamespace getty.derive.Serialize(@This(), .{});
    usingnamespace getty.derive.Deserialize(@This(), .{});

    x: i32,
    y: i32,
};

pub const main = fn() !void {
    const point = Point{ .x = 1, .y = 2 };

    // Convert the Point to a JSON string and back.
    const serialized = try getty.json.to_str(point);
    const deserialized = try getty.json.from_str(serialized);

    print("{}\n", .{serialized});   // {"x":1,"y":2}
    print("{}\n", .{deserialized}); // Point{ .x = 1, .y = 2 }
};
```
