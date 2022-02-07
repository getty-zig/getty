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

Getty is a serialization and deserialization framework for the Zig programming
language.

The main contribution of Getty is its data model, a set of types that
establishes a generic baseline from which serializers and deserializers can
operate. By working within Getty's data model, the set of possible
inputs/outputs for a serializer/deserializer is reduced from all possible types
in Zig to a subset of the types within the data model. The result is that
compliant (de)serializers are significantly simpler, support a wider variety of
types by default, and are more easily extensible.

Any type that is mapped to Getty's data model automatically becomes
(de)serializable. Out of the box, Getty maps a number of common types,
including many from the standard library. For types that are not already
supported by Getty, custom blocks can be provided to specify how a type can be
serialized or deserialized into.

## Installation

### Manual

1. Create a new Zig project.

    ```
    mkdir getty-json
    cd getty-json
    zig init-exe
    ```

2. Install Getty.

    ```
    git clone https://github.com/getty-zig/getty lib/getty
    ```

3. Add the following to `build.zig`.

    ```diff
    const std = @import("std");

    pub fn build(b: *std.build.Builder) void {
        ...

        const exe = b.addExecutable("getty-json", "src/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
    +   exe.addPackagePath("getty", "lib/getty/src/lib.zig");
        exe.install();

        ...
    }
    ```

### Gyro

1. Create a new Zig project.

    ```
    mkdir getty-json
    cd getty-json
    zig init-exe
    ```

2. Install and add Getty to the project.

    ```
    gyro add -s github getty-zig/getty
    ```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
