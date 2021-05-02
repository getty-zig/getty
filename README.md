<p align="center">
  <h1 align="center">Getty</h1>
  <p align="center">A framework for serializing and deserializing Zig data types.</p>
</p>

```zig
const std = @import("std");
const getty = @import("getty");

const Point = struct {
    usingnamespace getty.Serialize(Point, .{});
    usingnamespace getty.Deserialize(Point, .{});

    x: i32,
    y: i32,
};

pub fn main() anyerror!void {
    var point = Point{ .x = 1, .y = 2 };

    // Convert the Point to a JSON string.
    var serialized = try getty.json.toArrayList(std.heap.page_allocator, point);
    defer serialized.deinit();

    // Convert the JSON string back to a Point.
    var deserialized = try getty.json.fromSlice(serialized.items);

    // Print results
    std.debug.print("{s}\n", .{serialized.items}); // {"x":1,"y":2}
    std.debug.print("{}\n", .{deserialized});      // Point{ .x = 1, .y = 2 }
};
```
