const std = @import("std");

const StringLifetime = @import("../../lifetime.zig").StringLifetime;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;
const VisitStringReturn = @import("../../interfaces/visitor.zig").VisitStringReturn;

pub fn Visitor(comptime Array: type) type {
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

        const Value = Array;

        fn visitSeq(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            seq: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            var array: Value = undefined;
            var seen: usize = 0;

            switch (array.len) {
                0 => array = .{},
                else => for (&array) |*elem| {
                    if (try seq.nextElement(result_ally, Child)) |value| {
                        elem.* = value;
                        seen += 1;
                    } else {
                        // End of sequence was reached early.
                        return error.InvalidLength;
                    }
                },
            }

            // Expected end of sequence, but found an element.
            if ((try seq.nextElement(result_ally, Child)) != null) {
                return error.InvalidLength;
            }

            return array;
        }

        fn visitString(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
            _: StringLifetime,
        ) Deserializer.Err!VisitStringReturn(Value) {
            _ = result_ally;
            _ = scratch_ally;

            if (Child != u8) {
                return error.InvalidType;
            }

            var arr: Value = undefined;

            if (input.len != arr.len) {
                return error.InvalidLength;
            }

            @memcpy(&arr, input);
            return .{ .value = arr, .used = false };
        }

        const Child = std.meta.Child(Value);
    };
}
