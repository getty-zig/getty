<p align="center">
  <img alt="Getty" src="https://github.com/getty-zig/logo/blob/main/getty-full.svg" width="400px">
  <br/>
  <br/>
  <a alt="Version" href="https://github.com/getty-zig/getty/releases/latest"><img src="https://img.shields.io/badge/version-N/A-e2725b.svg"></a>
  <a alt="Zig" href="https://ziglang.org"><img src="https://img.shields.io/badge/Zig-master-fd9930.svg"></a>
  <a alt="License" href="https://github.com/getty-zig/getty/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-2598c9"></a>
</p>

<p align="center">A framework for serializing and deserializing Zig data types.</p>

## Quick Start

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

## Overview

Getty is a framework for serializing and deserializing Zig data types.

There are two components that comprise Getty: a **data model** and an interface for **data formats**. Together, these components enable the serialization and deserialization of any supported data type by any conforming data format.

Where many other languages rely on runtime reflection for serializing data, Getty makes use of Zig's powerful compile-time features. Not only does this avoid any overhead of reflection, it also allows for all data types supported by Getty (and therefore all data structures composed of those types) to be *automatically* serializable and deserializable.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
