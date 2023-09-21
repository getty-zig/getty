const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime Slice: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitSeq = visitSeq,
                .visitString = visitString,
            },
        );

        const Value = Slice;

        fn visitSeq(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            var list = std.ArrayList(Child).init(ally);
            errdefer list.deinit();

            while (try seq.nextElement(ally, Child)) |elem| {
                try list.append(elem);
            }

            if (@typeInfo(Value).Pointer.sentinel) |s| {
                const sentinel_char = @as(*const Child, @ptrCast(s)).*;
                return try list.toOwnedSliceSentinel(sentinel_char);
            }

            return try list.toOwnedSlice();
        }

        fn visitString(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Err!Value {
            if (Child != u8) {
                return error.InvalidType;
            }

            const sentinel = @typeInfo(Value).Pointer.sentinel;

            const output = try ally.alloc(u8, input.len + @intFromBool(sentinel != null));
            std.mem.copy(u8, output, input);

            if (sentinel) |s| {
                const sentinel_char = @as(*const u8, @ptrCast(s)).*;
                output[input.len] = sentinel_char;
                return output[0..input.len :sentinel_char];
            }

            return output;
        }

        const Child = std.meta.Child(Value);
    };
}
