const std = @import("std");
const interface = @import("../../interface.zig");

pub fn Visitor(comptime T: type) type {
    return struct {
        allocator: *std.mem.Allocator,

        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace interface.Visitor(
            *Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitSequence,
            visitString,
            undefined,
            undefined,
        );

        const Value = T;

        fn visitSequence(self: *Self, seqAccess: anytype) @TypeOf(seqAccess).Error!Value {
            var list = std.ArrayList(std.meta.Child(Value)).init(self.allocator);
            errdefer list.deinit();

            while (try seqAccess.nextElement(std.meta.Child(Value))) |elem| {
                try list.append(elem);
            }

            return list.toOwnedSlice();
        }

        fn visitString(self: *Self, comptime Error: type, input: anytype) Error!Value {
            // TODO: This type check (and InvalidType error) is a temporary
            // workaround for the case where the child type of `Value` isn't a
            // u8. In that situation, the compiler keeps both the .ArrayBegin
            // and the .String branches, which results in a compiler error since
            // `TokenStream.slice` returns a `[]const u8` and we can't `dupe` into,
            // say, a `[]const u32` from that.
            //
            // Maybe what we could do is use `visitSequence` and in the JSON
            // deserializer figure out what to do in the SequenceAccess based
            // on whether the input is an Array or a String. If this works, do we
            // even need a `visitString` method?
            if (std.meta.Child(Value) == u8)
                return try self.allocator.dupe(std.meta.Child(Value), input);

            return error.InvalidType;
        }
    };
}
