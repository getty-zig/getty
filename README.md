<p align="center">
  <h1 align="center">Getty</h1>
  <p align="center">A framework for serializing and deserializing Zig data types.</p>
</p>

```zig
const getty = @import("getty");
const print = @import("std").debug.print;

const Point = struct {
    usingnamespace getty.Serialize(@This(), .{});
    usingnamespace getty.Deserialize(@This(), .{});

    x: i32,
    y: i32,
};

pub const main = fn() !void {
    var point = Point{ .x = 1, .y = 2 };
    var serialized = try getty.json.to_str(&point);
    var deserialized = try getty.json.from_str(&serialized);

    print("{}\n", .{serialized});   // {"x":1,"y":2}
    print("{}\n", .{deserialized}); // Point{ .x = 1, .y = 2 }
};
```
