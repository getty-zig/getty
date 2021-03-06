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

Getty provides out-of-the-box support for a variety of standard library types, enables users to _locally_ customize the (de)serialization process for both existing and remote types, and maintains its own data model abstractions that serve as simple and generic baselines for serializers and deserializers.

## Resources

- [Website](https://getty.so)
- [Guide](https://getty.so/guide)
- [Examples](https://github.com/getty-zig/getty/tree/main/examples)
- [Installation](https://github.com/getty-zig/getty/wiki/Installation)
- [Contributing](https://getty.so/contributing)

## Quick Start

```zig
const std = @import("std");
const getty = @import("getty");

// Serializer supports the following types:
//
//  - Booleans
//  - Arrays
//  - Slices
//  - Tuples
//  - Vectors
//  - std.ArrayList
//  - std.TailQueue
//  - std.SinglyLinkedList
//  - std.BoundedArray
//  - and more!
const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        getty.default_st,
        getty.default_st,
        getty.TODO,
        Seq,
        getty.TODO,
        serializeBool,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        serializeSeq,
        undefined,
        undefined,
        undefined,
        undefined,
    );

    const Ok = void;
    const Error = error{ Foo, Bar };

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeSeq(_: @This(), _: ?usize) Error!Seq {
        std.debug.print("[", .{});
        return Seq{};
    }
};

const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        *@This(),
        Serializer.Ok,
        Serializer.Error,
        serializeElement,
        end,
    );

    fn serializeElement(self: *@This(), value: anytype) !void {
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *@This()) !Serializer.Ok {
        std.debug.print("]", .{});
    }
};

pub fn main() anyerror!void {
    const s = Serializer{};
    const value = .{ true, false };
    
    try getty.serialize(value, s.serializer()); // output: [true, false]
}
```
