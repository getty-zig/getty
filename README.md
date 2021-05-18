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
    std.debug.print("{s}\n", .{deserialized});     // Point{ .x = 1, .y = 2 }
};
```

## Table of Contents

<img align="right" width="170" src="https://github.com/getty-zig/logo/blob/main/getty-white.svg" />

- [Overview](#overview)
- [Data Model](#data-model)
- [Data Formats](#data-formats)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)

## Overview

Getty is a framework for serializing and deserializing Zig data types.

There are two components that comprise Getty: a **data model** and an interface for **data formats**. Together, these components enable the serialization and deserialization of any supported data type by any conforming data format.

Where many other languages rely on runtime reflection for serializing data, Getty makes use of Zig's powerful compile-time features. Not only does this avoid any overhead of reflection, it also allows for all data types supported by Getty (and therefore all data structures composed of those types) to be *automatically* serializable and deserializable.

<!-- ## Data Model -->

<!-- ## Data Formats -->

<!-- ## Examples -->

<!-- ## Contributing -->

## License

This project is released under the [MIT](LICENSE) license.
