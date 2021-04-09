<p align="center">
  <h1 align="center">Getty</h1>
  <p align="center">A framework for serializing and deserializing Zig data types.</p>
  <p align="center">
    <!--<a href="https://github.com/getty-zig/getty/releases"><img src="https://img.shields.io/badge/release-v0.1.0-blue"></a>-->
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  </p>
</p>

```zig
const print = @import("std").debug.print;
const getty = @import("getty");

const Point = struct {
    usingnamespace getty.Serialize(@This(), .{});
    usingnamespace getty.Deserialize(@This(), .{});

    x: i32,
    y: i32,
};

test "Convert a Point to a JSON string and back" {
    var point = Point{ .x = 1, .y = 2 };
    var serialized = try getty.json.to_str(&point);
    var deserialized = try getty.json.from_str(&serialized);

    print("{}\n", .{serialized});   // {"x":1,"y":2}
    print("{}\n", .{deserialized}); // Point{ .x = 1, .y = 2 }
};
```

## Quick Start

Consider the following data type:

```zig
const Point = struct {
    x: i32,
    y: i32,
};
```

In order for a `Point` to be serialized and deserialized by Getty, `Point` must
implement the `Serialize` and `Deserialize` interfaces. In short, this means that
`Point` must provide implementations for the following functions:

```zig
fn serialize(*Point, Serializer) !void     // Required by Serialize
fn deserialize(*Point, Deserializer) !void // Required by Deserialize
```

Thus, to implement `Serialize` and `Deserialize` for `Point`:

```zig
const getty = @import("getty");

const Point = struct {
    x: i32,
    y: i32,

    fn serialize(self: *Point, serializer: getty.ser.Serializer) void {
    	// ...
    }

    fn deserialize(self: *Point, deserializer: getty.ser.Deserializer) void {
    	// ...
    }
};
```

For convenience, Getty provides implementations for `serialize` and
`deserialize` that will automatically handle serialization and deserialization
for you! All you need to do is import them like so:

```zig
const getty = @import("getty");

const Point = struct {
    usingnamespace getty.Serialize(Point, .{});
    usingnamespace getty.Derialize(Point, .{});

    x: i32,
    y: i32,
};
```
