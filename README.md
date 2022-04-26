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

Getty is a framework for building robust, optimal, and reusable (de)serializers in the [Zig programming language](https://ziglang.org).

With Getty's data model abstractions, custom (de)serialization capabilities, and comprehensive support for standard library types, writing efficient, extensible, and type-safe (de)serializers in Zig has never been easier!

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
        serializeEnum,
        serializeNumber,
        serializeNumber,
        undefined,
        serializeNull,
        undefined,
        serializeSome,
        serializeString,
        undefined,
        serializeNull,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    fn serializeBool(_: @This(), value: bool) !Ok {
        std.debug.print("{}\n", .{value});
    }

    fn serializeEnum(self: @This(), value: anytype) !Ok {
        try self.serializeString(@tagName(value));
    }

    fn serializeNull(_: @This()) !Ok {
        std.debug.print("null\n", .{});
    }

    fn serializeNumber(_: @This(), value: anytype) !Ok {
        std.debug.print("{}\n", .{value});
    }

    fn serializeSome(self: @This(), value: anytype) !Ok {
        try getty.serialize(value, self.serializer());
    }

    fn serializeString(_: @This(), value: anytype) !Ok {
        std.debug.print("\"{s}\"\n", .{value});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();
    const values = .{ true, 123, 3.14, "Getty!", null };

    inline for (values) |v| {
        try getty.serialize(v, s);
    }
}
```

Output:

```console
$ zig build run
true
123
3.14e+00
"Getty!"
null
```

## Installation

### Manual

1. Add Getty to your project:

    ```
    git clone https://github.com/getty-zig/getty deps/getty
    ```

2. Add the following to `build.zig`:

    ```diff
    const std = @import("std");

    pub fn build(b: *std.build.Builder) void {
        ...

        const exe = b.addExecutable("my-project", "src/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
    +   exe.addPackagePath("getty", "deps/getty/src/lib.zig");
        exe.install();

        ...
    }
    ```

### Gyro

1. Add Getty to your project:

    ```
    gyro add -s github getty-zig/getty
    gyro fetch
    ```

2. Add the following to `build.zig`:

    ```diff
    const std = @import("std");
    +const pkgs = @import("deps.zig").pkgs;

    pub fn build(b: *std.build.Builder) void {
        ...

        const exe = b.addExecutable("my-project", "src/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
    +   pkgs.addAllTo(exe);
        exe.install();

        ...
    }
    ```

### Zigmod

1. Add the following to `zigmod.yml`:

    ```diff
    ...

    root_dependencies:
    +  - src: git https://gitub.com/getty-zig/getty
    ```

2. Fetch project dependencies:

    ```
    zigmod fetch
    ```

3. Add the following to `build.zig`:

    ```diff
    const std = @import("std");
    +const deps = @import("deps.zig");

    pub fn build(b: *std.build.Builder) void {
        ...

        const exe = b.addExecutable("my-project", "src/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
    +   deps.addAllTo(exe);
        exe.install();

        ...
    }
    ```
