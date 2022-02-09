<br/>

<p align="center">
  <img alt="Getty" src="https://github.com/getty-zig/logo/blob/main/getty-solid.svg" width="410px">
  <br/>
  <br/>
  <a href="https://github.com/getty-zig/getty/releases/latest"><img alt="Version" src="https://img.shields.io/badge/version-N/A-e2725b.svg?style=flat-square"></a>
  <a href="https://actions-badge.atrox.dev/getty-zig/getty/goto?ref=main"><img alt="Build status" src="https://img.shields.io/github/workflow/status/getty-zig/getty/ci?label=build&style=flat-square" /></a>
  <a href="https://ziglang.org/download"><img alt="Zig" src="https://img.shields.io/badge/zig-master-fd9930.svg?style=flat-square"></a>
  <a href="https://github.com/getty-zig/getty/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square"></a>
</p>

## Overview

Getty is a serialization and deserialization framework for the [Zig programming
language](https://ziglang.org).

The main contribution of Getty is its data model, a set of types that
establishes a generic baseline from which serializers and deserializers can
operate. Using the data model, serializers and deserializers:

- Automatically support a number of Zig data types (including many within the standard library).
- Can serialize or deserialize into any data type mapped to Getty's data model.
- Can perform custom serialization and deserialization.
- Become much simpler than equivalent, handwritten alternatives.

## Installation

### Gyro

1. Make Getty a project dependency:

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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
