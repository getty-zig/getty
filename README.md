# Getty

<br>

<p align="center">
  <img alt="Getty" src="https://github.com/getty-zig/logo/blob/main/getty-solid.svg" width="410px">
  <br>
  <br>
  <br>
  <a href="https://github.com/getty-zig/getty/releases/latest"><img alt="Version" src="https://img.shields.io/github/v/release/getty-zig/getty?include_prereleases&label=Version"></a>
  <a href="https://ziglang.org/download"><img alt="Zig" src="https://img.shields.io/badge/Zig-master-fd9930.svg"></a>
  <a href="https://github.com/getty-zig/getty/actions/workflows/test.yml"><img alt="Build status" src="https://img.shields.io/github/actions/workflow/status/getty-zig/getty/test.yml?branch=main&label=Build" /></a>
  <a href="https://discord.gg/njDA67U5ph"><img alt="Discord" src="https://img.shields.io/discord/1016029822172024955?color=7289da&label=Discord" /></a>
  <a href="https://github.com/getty-zig/getty/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/License-MIT-blue"></a>
</p>

<br>

Getty is a framework for building __robust__, __optimal__, and __reusable__ (de)serializers in Zig.

- Compile-time (de)serialization.
- Out-of-the-box support for a variety of `std` types.
- Granular customization for existing and remote types.
- Data models that serve as simple and generic baselines for (de)serializers.

## Quick Start

<details>
<summary>
  <code>build.zig</code>
</summary>
<br>

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const opts = .{ .target = target, .optimize = optimize };
    const json_mod = b.dependency("json", opts).module("json");

    const exe = b.addExecutable(.{
        .name = "quick-start",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.addModule("json", json_mod);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
```

</details>

<details>
<summary>
  <code>build.zig.zon</code>
</summary>
<br>

```zig
.{
    .name = "quick-start",
    .version = "0.1.0",
    .paths = .{""},
    .dependencies = .{
        .json = .{
            .url = "https://github.com/getty-zig/json/archive/3e3cf7b.tar.gz",
            .hash = "122017ccb426b5f5690fdda438134852e940796b0ac619eb2648782a7879146f4fcd",
        },
    },
}
```

</details>

<details open>
<summary>
  <code>src/main.zig</code>
</summary>
<br>

```zig
const std = @import("std");
const json = @import("json");

const ally = std.heap.page_allocator;

const Point = struct {
    x: i32,
    y: i32,
};

pub fn main() !void {
    const value = Point{ .x = 1, .y = 2 };

    // Serialize a Point value into JSON.
    const serialized = try json.toSlice(ally, value);
    defer ally.free(serialized);

    // Deserialize JSON data into a Point value.
    const deserialized = try json.fromSlice(ally, Point, serialized);

    // Print results.
    std.debug.print("{s}\n", .{serialized});  // {"x":1,"y":2}
    std.debug.print("{}\n", .{deserialized}); // main.Point{ .x = 1, .y = 2 }
}
```

</details>

## Installation

1. Declare Getty as a project dependency with `zig fetch`:

    ```sh
    # Latest version
    zig fetch --save git+https://github.com/getty-zig/getty.git#master

    # Specific version
    zig fetch --save git+https://github.com/getty-zig/getty.git#<COMMIT>
    ```

2. Expose Getty as a module in your project's `build.zig`:

    ```zig
    pub fn build(b: *std.Build) void {
        const target = b.standardTargetOptions(.{});
        const optimize = b.standardOptimizeOption(.{});

        const opts = .{ .target = target, .optimize = optimize };      // 👈
        const getty_mod = b.dependency("getty", opts).module("getty"); // 👈

        const exe = b.addExecutable(.{
            .name = "my-project",
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("getty", getty_mod); // 👈

        // ...
    }
    ```

3. Import Getty into your code:

    ```zig
    const getty = @import("getty");
    ```

## Resources

- [Website](https://getty.so/)
- [Tutorial](https://getty.so/user-guide/tutorial/)
- [Examples](examples)
- [API Reference](https://docs.getty.so/)
- [Contributing](https://getty.so/contributing/)
