<p align="center">:zap: <strong>Getty is in early development. Things might break or change!</strong> :zap:</p>
<br/>

<p align="center">
  <img alt="Getty" src="https://github.com/getty-zig/logo/blob/main/getty-solid.svg" width="410px">
  <br/>
  <br/>
  <a alt="Version" href="https://github.com/getty-zig/getty/releases/latest"><img src="https://img.shields.io/badge/version-N/A-e2725b.svg"></a>
  <a alt="Zig" href="https://ziglang.org/download"><img src="https://img.shields.io/badge/zig-master-fd9930.svg"></a>
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

    // Convert Point to JSON string
    var serialized = try json.toString(std.heap.page_allocator, point);
    defer std.heap.page_allocator.free(serialized);

    // Convert JSON string to Point
    var deserialized = try json.fromString(Point, serialized);

    // Print results
    std.debug.print("{s}\n", .{serialized});   // {"x":1,"y":2}
    std.debug.print("{s}\n", .{deserialized}); // Point{ .x = 1, .y = 2 }
}
```

## Overview

Getty is a serialization and deserialization framework for the Zig programming language.

At its core, Getty is composed of two components: a **data model** and a **data
format interface**. Together, they allow for any supported data type to be
serialized into any conforming data format, and likewise for any conforming
data format to be deserialized into any supported data type.

Getty takes advantage of Zig's powerful compile-time features when serializing
and deserializing data. As a result, Getty is able to avoid most, if not all,
of the overhead that often arises when using more traditional serialization
methods, such as runtime reflection. Furthermore, `comptime` allows for all
data types supported by Getty (and therefore all data structures composed of
those types) to *automatically* become serializable and deserializable.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
