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

By maintaining a **data model** (i.e., a set of supported types) and making use
of **data format interfaces** (i.e., how to convert between data and format),
Getty enables any supported data type to be serialized into any conforming data
format, and likewise any conforming data format to be deserialized into any
data type.

Getty leverages the powerful compile-time features of Zig when serializing and
deserializing data, allowing it to avoid the runtime overhead associated with
other serialization methods such as reflection.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
