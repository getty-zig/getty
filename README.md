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
- [API Reference](https://docs.getty.so)
- [Wiki](https://github.com/getty-zig/getty/wiki)

## Examples

### Minimal Serializer

```zig
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Serializer,
        void,
        error{},
        null,
        null,
        null,
        null,
        null,
        .{},
    );
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    try getty.serialize(true, s); // ERROR: serializeBool is not implemented
}
```

### Boolean Serializer

```zig
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Serializer,
        Ok,
        Error,
        null,
        null,
        null,
        null,
        null,
        .{
            .serializeBool = serializeBool,
        },
    );

    const Ok = void;
    const Error = error{};

    fn serializeBool(_: Serializer, value: bool) Error!Ok {
        std.debug.print("{}\n", .{value});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    try getty.serialize(true, s);  // true
    try getty.serialize(false, s); // false
}
```

### Sequence Serializer

```zig
const std = @import("std");
const getty = @import("getty");

const allocator = std.heap.page_allocator;

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
        .{
            .serializeBool = serializeBool,
            .serializeSeq = serializeSeq,
        },
    );

    const Ok = void;
    const Error = error{};

    fn serializeBool(_: Serializer, value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeSeq(_: Serializer, _: ?usize) Error!Seq {
        std.debug.print("[", .{});
        return Seq{};
    }

    const Seq = struct {
        first: bool = true,

        pub usingnamespace getty.ser.Seq(
            *Seq,
            Ok,
            Error,
            .{
                .serializeElement = serializeElement,
                .end = end,
            },
        );

        fn serializeElement(self: *Seq, value: anytype) Error!void {
            switch (self.first) {
                true => self.first = false,
                false => std.debug.print(", ", .{}),
            }

            try getty.serialize(value, (Serializer{}).serializer());
        }

        fn end(_: *Seq) Error!Ok {
            std.debug.print("]\n", .{});
        }
    };
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    // Primitives
    try getty.serialize(.{ true, false }, s);                // [true, false]
    try getty.serialize([_]bool{ true, false }, s);          // [true, false]
    try getty.serialize(&&&[_]bool{ true, false }, s);       // [true, false]
    try getty.serialize(@Vector(2, bool){ true, false }, s); // [true, false]

    // std.ArrayList
    var list = std.ArrayList(bool).init(allocator);
    defer list.deinit();
    try list.appendSlice(&.{ true, false });
    try getty.serialize(list, s); // [true, false]

    // std.BoundedArray
    var arr = try std.BoundedArray(bool, 2).fromSlice(&.{ true, false });
    try getty.serialize(arr, s); // [true, false]

}
```

### Minimal Deserializer

```zig
const getty = @import("getty");

const Deserializer = struct {
    pub usingnamespace getty.Deserializer(
        Deserializer,
        error{},
        null,
        null,
        .{},
    );
};

pub fn main() anyerror!void {
    const d = (Deserializer{}).deserializer();

    try getty.deserialize(null, bool, d); // ERROR: deserializeBool is not implemented
}
```

### Boolean Deserializer

```zig
const std = @import("std");
const getty = @import("getty");

const Deserializer = struct {
    tokens: std.json.TokenStream,

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Self,
        Error,
        null,
        null,
        .{
            .deserializeBool = deserializeBool,
        },
    );

    const Error = getty.de.Error || std.json.TokenStream.Error;

    const De = Self.@"getty.Deserializer";

    pub fn init(s: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(s) };
    }

    fn deserializeBool(self: *Self, allocator: ?std.mem.Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }
        }

        return error.InvalidType;
    }
};

pub fn main() anyerror!void {
    var d = Deserializer.init("true");
    const v = try getty.deserialize(null, bool, d.deserializer());

    std.debug.print("{}, {}\n", .{ v, @TypeOf(v) }); // true, bool
}
```

### Sequence Deserializer

```zig
const std = @import("std");
const getty = @import("getty");

const Deserializer = struct {
    tokens: std.json.TokenStream,

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Self,
        Error,
        null,
        null,
        .{
            .deserializeBool = deserializeBool,
            .deserializeSeq = deserializeSeq,
        },
    );

    const Error = getty.de.Error || std.json.TokenStream.Error;

    const De = Self.@"getty.Deserializer";

    pub fn init(s: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(s) };
    }

    fn deserializeBool(self: *Self, allocator: ?std.mem.Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }
        }

        return error.InvalidType;
    }

    fn deserializeSeq(self: *Self, allocator: ?std.mem.Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .ArrayBegin) {
                var sa = SeqAccess{ .de = self };
                return try v.visitSeq(allocator, De, sa.seqAccess());
            }
        }

        return error.InvalidType;
    }

    const SeqAccess = struct {
        de: *Self,

        pub usingnamespace getty.de.SeqAccess(
            *@This(),
            Self.Error,
            .{
                .nextElementSeed = nextElementSeed,
            },
        );

        fn nextElementSeed(self: *@This(), allocator: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
            const element = seed.deserialize(allocator, self.de.deserializer()) catch |err| {
                // Encountered end of JSON before ']', so return an error.
                if (self.de.tokens.i - 1 >= self.de.tokens.slice.len) {
                    return err;
                }

                // If ']' is encountered, return null. Otherwise, return an error.
                return switch (self.de.tokens.slice[self.de.tokens.i - 1]) {
                    ']' => null,
                    else => err,
                };
            };

            return element;
        }
    };
};

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    var d = Deserializer.init("[true, false]");
    const v = try getty.deserialize(allocator, std.ArrayList(bool), d.deserializer());
    defer v.deinit();

    std.debug.print("{any}, {}\n", .{ v.items, @TypeOf(v) }); // { true, false }, array_list.ArrayListAligned(bool,null)
}
```
