const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime Slice: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace getty.de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitSeq,
            undefined,
            visitString,
            undefined,
            undefined,
        );

        const Value = Slice;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var list = std.ArrayList(Child).init(allocator.?);
            errdefer getty.de.free(allocator.?, list);

            while (try seq.nextElement(allocator, Child)) |elem| {
                try list.append(elem);
            }

            return list.toOwnedSlice();
        }

        fn visitString(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
            errdefer getty.de.free(allocator.?, input);

            // TODO: This type check (and InvalidType error) is a temporary
            // workaround for the case where the child type of `Value` isn't a
            // u8. In that situation, the compiler keeps both the .ArrayBegin
            // and the .String branches, which results in a compiler error since
            // `TokenStream.slice` returns a `[]const u8` and we can't `dupe` into,
            // say, a `[]const u32` from that.
            //
            // Maybe what we could do is use `visitSeq` and in the JSON
            // deserializer figure out what to do in the Seq based on
            // whether the input is an Array or a String. If this works, do
            // we even need a `visitString` method?
            return if (Child == u8) input else error.InvalidType;
        }

        const Child = std.meta.Child(Value);
    };
}
