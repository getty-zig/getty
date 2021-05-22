<p align="center">:zap: <strong>Getty is in early development. Things might break or change!</strong> :zap:</p>
<br/>

<p align="center">
  <img alt="Getty" src="https://github.com/getty-zig/logo/blob/main/getty-solid.svg" width="400px">
  <br/>
  <br/>
  <a alt="Version" href="https://github.com/getty-zig/getty/releases/latest"><img src="https://img.shields.io/badge/version-N/A-e2725b.svg"></a>
  <a alt="Zig" href="https://ziglang.org/download"><img src="https://img.shields.io/badge/Zig-master-fd9930.svg"></a>
  <a alt="Build" href="https://github.com/getty-zig/getty/actions"><img src="https://github.com/getty-zig/getty/actions/workflows/ci.yml/badge.svg"></a>
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

    // Convert Point to JSON string.
    var serialized = try json.toString(std.heap.page_allocator, point);
    defer std.heap.page_allocator.free(serialized);

    // Convert JSON string to Point.
    var deserialized = try json.fromString(serialized);

    // Print results.
    std.debug.print("{s}\n", .{serialized});   // {"x":1,"y":2}
    std.debug.print("{s}\n", .{deserialized}); // Point{ .x = 1, .y = 2 }
}
```

## Overview

Getty is a serialization and deserialization framework for the Zig programming language.

There are two components in Getty: a **data model** and a **data format interface**. Together, they allow any supported data type to be serialized or deserialized by any conforming data format.

Getty takes advantage of Zig's powerful compile-time features when serializing and deserializing data. Because of this, Getty avoids any overhead associated with more costly methods, such as runtime reflection. In addition, `comptime` enables all data types supported by Getty (and therefore all data structures composed of those types) to *automatically* become serializable and deserializable.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
