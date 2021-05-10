<p align="center">
  <h1 align="center">Getty</h1>
  <p align="center"><b>NOTE: Getty is still in early development. Things might break or change.</b></p>
  <p align="center">A framework for serializing and deserializing Zig data types.</p>
</p>

```zig
const std = @import("std");
const json = @import("getty_json");

const Point = struct {
    x: i32,
    y: i32,
};

pub fn main() anyerror!void {
    var point = Point{ .x = 1, .y = 2 };

    // Convert the Point to a JSON string.
    var serialized = try json.toArrayList(std.heap.page_allocator, point);
    defer serialized.deinit();

    // Convert the JSON string back to a Point.
    var deserialized = try json.fromSlice(serialized.items);

    // Print results
    std.debug.print("{s}\n", .{serialized.items}); // {"x":1,"y":2}
    std.debug.print("{}\n", .{deserialized});      // Point{ .x = 1, .y = 2 }
};
```
