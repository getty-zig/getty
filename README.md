<br/>

<p align="center">
  <img alt="Getty" src="https://github.com/getty-zig/logo/blob/main/getty-solid.svg" width="410px">
  <br/>
  <br/>
  <a href="https://github.com/getty-zig/getty/releases/latest"><img alt="Version" src="https://img.shields.io/github/v/release/getty-zig/getty?include_prereleases&label=version&style=flat-square"></a>
  <a href="https://github.com/getty-zig/getty/actions/workflows/ci.yml"><img alt="Build status" src="https://img.shields.io/github/workflow/status/getty-zig/getty/ci?style=flat-square" /></a>
  <a href="https://ziglang.org/download"><img alt="Zig" src="https://img.shields.io/badge/zig-master-fd9930.svg?style=flat-square"></a>
  <a href="https://github.com/getty-zig/getty/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square"></a>
</p>

## Overview

Getty is a framework for building __robust__, __optimal__, and __reusable__ (de)serializers in Zig.

Getty provides out-of-the-box support for a variety of standard library types, enables users to _locally_ customize the (de)serialization process for both existing and remote types, and maintains its own data model abstractions that serve as simple and generic baselines for serializer and deserializer implementations.

## Resources

- [Website](https://getty.so)
- [Guide](https://getty.so/guide)
- [Wiki](https://github.com/getty-zig/getty/wiki/)

## Quick Start

```zig
const std = @import("std");
const getty = @import("getty");

// Serializer is a Getty serializer that supports the following types:
//
//  - Booleans
//  - Arrays
//  - Slices
//  - Tuples
//  - Vectors
//  - std.ArrayList
//  - std.SinglyLinkedList
//  - std.TailQueue
//  - std.BoundedArray
//  - and more!
const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Serializer,
        Ok,
        Error,
        null,
        null,
        null,
        Seq,
        null,
        .{ .serializeBool = serializeBool, .serializeSeq = serializeSeq },
    );

    const Ok = void;
    const Error = error{ Foo, Bar };

    fn serializeBool(_: Serializer, value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeSeq(_: Serializer, _: ?usize) Error!Seq {
        std.debug.print("[", .{});
        return Seq{};
    }
};

// Seq defines the serialization process for sequences.
const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        *Seq,
        Serializer.Ok,
        Serializer.Error,
        .{ .serializeElement = serializeElement, .end = end },
    );

    fn serializeElement(self: *Seq, value: anytype) Serializer.Error!void {
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *Seq) Serializer.Error!Serializer.Ok {
        std.debug.print("]", .{});
    }
};

pub fn main() anyerror!void {
    try getty.serialize(.{ true, false }, (Serializer{}).serializer()); // [true, false]
}
```
