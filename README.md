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
        std.debug.print("BOOL: {}\n", .{value});
    }

    fn serializeInt(_: @This(), value: anytype) !Ok {
        std.debug.print("INT: {}\n", .{value});
    }

    fn serializeString(_: @This(), value: anytype) !Ok {
        std.debug.print("STRING: \"{s}\"\n", .{value});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    try getty.serialize(true, s);
    try getty.serialize(1234, s);
    try getty.serialize("Getty!", s);
}
```

```sh
$ zig build run
BOOL: true
INT: 1234
STRING: "Getty!"
```

## Installation

### Manual

1. Add Getty to your project:

    ```
    git clone https://github.com/getty-zig/getty lib/getty
    ```

2. Add the following to `build.zig`:

    ```diff
    const std = @import("std");

    pub fn build(b: *std.build.Builder) void {
        ...

        const exe = b.addExecutable("my-project", "src/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
    +   exe.addPackagePath("getty", "lib/getty/src/lib.zig");
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

## Contributing

See [Contributing](https://getty.so/contributing).
