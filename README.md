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

## Quick Start

```zig
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        getty.default_st,
        getty.default_st,
        getty.TODO,
        getty.TODO,
        getty.TODO,
        serializeBool,
        undefined,
        undefined,
        serializeInt,
        undefined,
        undefined,
        undefined,
        undefined,
        serializeString,
        undefined,
        undefined,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    fn serializeBool(_: @This(), value: bool) !Ok {
        std.debug.print("{}\n", .{value});
    }

    fn serializeInt(_: @This(), value: anytype) !Ok {
        std.debug.print("{}\n", .{value != 0});
    }

    fn serializeString(_: @This(), value: anytype) !Ok {
        std.debug.print("{}\n", .{value.len > 0});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    try getty.serialize(true, s);    // output: true
    try getty.serialize(false, s);   // output: false
    try getty.serialize(1, s);       // output: true
    try getty.serialize(0, s);       // output: false
    try getty.serialize("Getty", s); // output: true
    try getty.serialize("", s);      // output: false
}
```

## Resources

- [Website](https://getty.so)
- [Guide](https://getty.so/guide)
- [Examples](https://github.com/getty-zig/getty/tree/main/examples)
- [Installation](https://github.com/getty-zig/getty/wiki/Installation)
- [Contributing](https://getty.so/contributing)
