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

Getty is a serialization and deserialization framework for the Zig programming
language.

At its core, Getty revolves around two concepts: a **data model** and **data
format interfaces**. Together, they allow for any supported data type to be
serialized into any conforming data format, and likewise for any conforming
data format to be deserialized into any Zig data type.

Getty takes advantage of Zig's powerful compile-time features when serializing
and deserializing data. As a result, Getty is able to avoid most, if not all,
of the overhead that often arises when using more traditional serialization
methods, such as runtime reflection. Furthermore, `comptime` allows for all
data types supported by Getty (and therefore all data structures composed of
those types) to *automatically* become serializable and deserializable.

## Installation

### Gyro

```sh
gyro add -s github getty-zig/getty
```

### Git

```sh
git submodule add https://github.com/getty-zig/getty
git commit -am "Add Getty module"
```

## Quick Start

Let's now take a whirlwind tour of Getty by writing a serializer!

The first thing we need to do is specify the data format supported by our
serializer. For this example, we'll keep things simple and use a format that
consists of just the values `true` and `false`.

Next, we need to specify how to convert each type within Getty's data model
into our data format. We'll use the following specification:

<details>
  <summary><b>Specification</b></summary>
  <br>

  <details>
  <summary>Booleans</summary>
  <br>
  <ul>
    <li><code>true</code> → <code>true</code></li>
    <li><code>false</code> → <code>true</code></li>
  </ul>
  </details>

  <details>
  <summary>Enums</summary>
  <br>
  <ul>
    <li>All variants → <code>true</code></li>
  </ul>
  </details>

  <details>
  <summary>Floats</summary>
  <br>
  <ul>
    <li>Value is <code>> 0.0</code> → <code>true</code></li>
    <li>Value is <code>≤ 0.0</code> → <code>false</code></li>
  </ul>
  </details>

  <details>
  <summary>Integers</summary>
  <br>
  <ul>
    <li>Value is <code>> 0</code> → <code>true</code></li>
    <li>Value is <code>≤ 0</code> → <code>false</code></li>
  </ul>
  </details>

  <details>
  <summary>Null</summary>
  <br>
  <ul>
    <li><code>null</code> → <code>false</code></li>
  </ul>
  </details>

  <details>
  <summary>Strings</summary>
  <br>
  <ul>
    <li>Length is <code>> 0</code> → <code>true</code></li>
    <li>Length is <code>0</code> → <code>false</code></li>
  </ul>
  </details>

  <details>
  <summary>Maps, Sequences, Structs, and Tuples</summary>
  <br>
  <ul>
    <li>Not supported for brevity.
  </ul>
  </details>
</details>

With that out of the way, all that's left to do is write our serializer!

```zig
const getty = @import("getty");

const Serializer = struct {
    const Self = @This();

    // Define associated types for `getty.Serializer`.
    const Ok = bool;
    const Error = error{Data};
    const Map = Self;
    const Seq = Self;
    const Struct = Self;
    const Tuple = Self;

    // Define required methods for `getty.Serializer`.
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

    fn serializeString(self: *Self, value: anytype) Error!Ok {
        return if (value.len > 0) true else false;
    }

    fn serializeVariant(_: *Self, value: anytype) Error!Ok {
        _ = value;

        return true;
    }

    fn serializeMap(self: *Self, keys: ?usize) Error!Ok {
        _ = self;
        _ = keys;

        @panic("Not supported");
    }

    fn serializeSequence(self: *Self, length: ?usize) Error!Ok {
        _ = self;
        _ = length;

        @panic("Not supported");
    }

    fn serializeStruct(self: *Self, name: []const u8, fields: usize) Error!Ok {
        _ = self;
        _ = name;
        _ = fields;

        @panic("Not supported");
    }

    fn serializeTuple(self: *Self, length: ?usize) Error!Ok {
        _ = self;
        _ = length;

        @panic("Not supported");
    }

    // Implement `getty.Serializer`.
    pub fn serializer(self: *Self) S {
        return .{ .context = self };
    }

    const S = getty.Serializer(
        *Self,
        Ok,
        Error,
        Map,
        Seq,
        Struct,
        Tuple,
        serializeBool,
        serializeFloat,
        serializeInt,
        serializeMap,
        serializeNull,
        serializeSequence,
        serializeString,
        serializeStruct,
        serializeTuple,
        serializeVariant,
    );
};
```

And that's it! We can now serialize (almost) all the things!

```zig
const equal = @import("std").testing.expectEqual;

test {
    var serializer = Serializer{};
    const s = serializer.serializer();

    // Bools
    try equal(true, try getty.serialize(s, true));
    try equal(false, try getty.serialize(s, false));

    // Floats
    try equal(true, try getty.serialize(s, 1.0));
    try equal(false, try getty.serialize(s, 0.0));

    // Integers
    try equal(true, try getty.serialize(s, 1));
    try equal(false, try getty.serialize(s, 0));

    // Strings
    try equal(true, try getty.serialize(s, "Getty"));
    try equal(false, try getty.serialize(s, ""));
}
```

<!-- let's look at the `getty.Serializer` interface, which we'll be implementing:

```zig
pub fn Serializer(
    // Implementer type
    comptime Context: type,

    // Associated types
    comptime O: type,
    comptime E: type,
    comptime M: type,
    comptime SE: type,
    comptime ST: type,
    comptime T: type,

    // Methods
    comptime boolFn: fn (Context, value: bool) E!O,
    comptime floatFn: fn (Context, value: anytype) E!O,
    comptime intFn: fn (Context, value: anytype) E!O,
    comptime nullFn: fn (Context) E!O,
    comptime sequenceFn: fn (Context, ?usize) E!SE,
    comptime stringFn: fn (Context, value: anytype) E!O,
    comptime mapFn: fn (Context, ?usize) E!M,
    comptime structFn: fn (Context, comptime []const u8, usize) E!ST,
    comptime tupleFn: fn (Context, ?usize) E!T,
    comptime variantFn: fn (Context, value: anytype) E!O,
) type
```

As you can see, interfaces in Getty are just functions.

The parameters of an interface specify what the interface requires from its
implementers. In this case, `getty.Serializer` requires:

1. The type of the implementer
2. Various associated types
3. Various methods

The return type of an interface is called the **interface type**. Whenever you
want to take a `getty.Serializer` as a function argument or call the
`serializeBool` method of a `getty.Serializer`, this type is what you use.

To implement an interface, you provide a function in your implementing type
that returns a value of the interface type. For example:

```zig
const MyType = struct {
    // Define implementor type
    const Self = @This();

    // Define required methods
    fn foo() void {}

    // Implement `Interface`
    pub fn interface(self: *Self) Interface(*Self, foo) {
        return .{ .context = self };
    }
};
``` -->

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
