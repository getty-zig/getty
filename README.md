<p align="center">:zap: <strong>Getty is in early development. Things might break or change!</strong> :zap:</p>
<br/>

<p align="center">
  <img alt="Getty" src="https://github.com/getty-zig/logo/blob/main/getty-solid.svg" width="410px">
  <br/>
  <br/>
  <a href="https://github.com/getty-zig/getty/releases/latest"><img alt="Version" src="https://img.shields.io/badge/version-N/A-e2725b.svg?style=flat-square"></a>
  <a href="https://ziglang.org/download"><img alt="Zig" src="https://img.shields.io/badge/zig-master-fd9930.svg?style=flat-square"></a>
  <a href="https://actions-badge.atrox.dev/getty-zig/getty/goto?ref=main"><img alt="Build status" src="https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fgetty-zig%2Fgetty%2Fbadge%3Fref%3Dmain&style=flat-square" /></a>
  <a href="https://github.com/getty-zig/getty/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square"></a>
</p>

<p align="center">A framework for serializing and deserializing Zig data types.</p>

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

<!-- ## Quick Start

```zig
const std = @import("std");
const getty = @import("getty");

/// Serializes a subset of Getty's data model into a boolean value.
///
/// TODO: Put this somewhere not in the readme
/// TODO: Add associated types
const Serializer = struct {
    const Self = @This();

    const Ok = bool;
    const Error = error{};

    /// Implements `getty.ser.Serializer`.
    pub fn serializer(self: *Self) S {
        return .{ .context = self };
    }

    const S = getty.ser.Serializer(
        *Self,
        Ok,
        Error,
        Self,
        Self,
        Self,
        _S.serializeBool,
        _S.serializeFloat,
        _S.serializeInt,
        _S.serializeNull,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
    );

    const _S = struct {
        fn serializeBool(_: *Self, value: bool) Error!Ok {
            return value;
        }

        fn serializeFloat(_: *Self, value: anytype) Error!Ok {
            return if (value > 0.0) true else false;
        }

        fn serializeInt(_: *Self, value: anytype) Error!Ok {
            return if (value > 0) true else false;
        }

        fn serializeNull(_: *Self) Error!Ok {
            return false;
        }
    };
};

pub fn main() anyerror!void {
    // Create serializer
    var serializer = Serializer{};
    const s = serializer.serializer();

    // Convert integers into bools
    const t = try getty.serialize(&s, 1);
    const f = try getty.serialize(&s, 0);

    // Print results
    std.debug.print("{}\n", .{t}); // true
    std.debug.print("{}\n", .{f}); // false
}
``` -->

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
