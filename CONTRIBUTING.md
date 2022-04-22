# Contributing to Getty

Contributions to Getty are very welcome! This document provides some guidelines
and information to help you get started.

## First Steps

If you're new to Getty, the best place to get started is
[`src/ser/blocks/`](src/ser/blocks/).

The directory contains files for every data type Getty knows how to serialize:
booleans, integers, arrays, `std.ArrayList`, it's all in there! The plan is to
add support for most of the standard library types, so a great way to start
contributing is by finding a data type in `std` that you like and making a file
for it!

The files are short and simple, so it shouldn't be too hard. You can probably
get by just from looking at a few files and copying and pasting. If you do have
any questions though or don't know what to do, feel free to create an issue and
I'll help you out! The documentation for Getty is currently a work-in-progress
so please don't hesitate to ask for help.
