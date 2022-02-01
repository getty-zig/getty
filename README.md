<p align="center">:zap: <strong>Getty is in early development. Things might break or change!</strong> :zap:</p>
<br/>

<p align="center">
  <img alt="Getty" src="https://github.com/getty-zig/logo/blob/main/getty-solid.svg" width="410px">
  <br/>
  <br/>
  <a href="https://github.com/getty-zig/getty/releases/latest"><img alt="Version" src="https://img.shields.io/badge/version-N/A-e2725b.svg?style=flat-square"></a>
  <a href="https://ziglang.org/download"><img alt="Zig" src="https://img.shields.io/badge/zig-0.9.0-fd9930.svg?style=flat-square"></a>
  <a href="https://actions-badge.atrox.dev/getty-zig/getty/goto?ref=main"><img alt="Build status" src="https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fgetty-zig%2Fgetty%2Fbadge%3Fref%3Dmain&style=flat-square" /></a>
  <a href="https://github.com/getty-zig/getty/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square"></a>
</p>

<p align="center">A framework for serializing and deserializing Zig data types.</p>

## Overview

Getty is a serialization and deserialization framework for the Zig programming
language.

At its core, Getty is composed of two things: a **data model** (a set of
supported types) and **data format interfaces** (specifications of how to
convert between data and format). Together, these components enable any
supported data type to be serialized into any conforming data format, and
likewise any conforming data format to be deserialized into any data type.

By leveraging the powerful compile-time features of Zig, Getty is able to avoid
the inherent runtime overhead of more traditional serialization methods such as
reflection. Additionally, `comptime` enables all supported data types to
automatically become serializable and deserializable.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
