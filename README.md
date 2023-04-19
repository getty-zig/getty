# Getty

<br>

<p align="center">
  <img alt="Getty" src="https://github.com/getty-zig/logo/blob/main/getty-solid.svg" width="410px">
  <br>
  <br>
  <br>
  <a href="https://github.com/getty-zig/getty/releases/latest"><img alt="Version" src="https://img.shields.io/github/v/release/getty-zig/getty?include_prereleases&label=version"></a>
  <a href="https://github.com/getty-zig/getty/actions/workflows/test.yml"><img alt="Build status" src="https://img.shields.io/github/actions/workflow/status/getty-zig/getty/test.yml?branch=develop" /></a>
  <a href="https://discord.gg/njDA67U5ph"><img alt="Discord" src="https://img.shields.io/discord/1016029822172024955?color=7289da&label=discord" /></a>
  <a href="https://github.com/getty-zig/getty/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue"></a>
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
    .version = "0.0.0",
    .dependencies = .{
        .json = .{
            .url = "https://github.com/getty-zig/json/archive/5a64449.tar.gz",
            .hash = "122087fe6d2b141548103e98e4324ac0ab889e7d50d82e186f396d90f55a942aef61",
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

const allocator = std.heap.page_allocator;

const Point = struct {
    x: i32,
    y: i32,
};

pub fn main() !void {
    const value = Point{ .x = 1, .y = 2 };

    // Serialize a Point value into JSON.
    const serialized = try json.toSlice(allocator, value);
    defer allocator.free(serialized);

    // Deserialize JSON data into a Point value.
    const deserialized = try json.fromSlice(null, Point, serialized);

    // Print results.
    std.debug.print("{s}\n", .{serialized});
    std.debug.print("{}\n", .{deserialized});
}
```

</details>

## Resources

- [Website](https://getty.so/)
- [Installation](https://getty.so/user-guide/installation/)
- [Tutorial](https://getty.so/user-guide/tutorial/)
- [Examples](examples)
- [API Reference](https://docs.getty.so/)
- [Contributing](https://getty.so/contributing/)
