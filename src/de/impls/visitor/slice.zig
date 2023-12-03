const std = @import("std");

const StringLifetime = @import("../../lifetime.zig").StringLifetime;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;
const VisitStringReturn = @import("../../interfaces/visitor.zig").VisitStringReturn;

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

        // input is only used directly if it the following are true:
        //
        //   1. input is a Heap value.
        //   2. The sentinel values of input and Value match.
        //   3. Either constness of input and Value match or are compatible
        //      (i.e., Value is const and input is not const).
        //
        //  Otherwise, input is copied into a new slice.
        fn visitString(
            _: Self,
            ally: std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
            lt: StringLifetime,
        ) Deserializer.Err!VisitStringReturn(Value) {
            if (Child != u8) {
                return error.InvalidType;
            }

            const v_info = @typeInfo(Value).Pointer;

            const safe = comptime safe: {
                const i_info = @typeInfo(@TypeOf(input)).Pointer;

                const sentinels_match = (v_info.sentinel == null) == (i_info.sentinel == null);
                const constness_match = v_info.is_const == i_info.is_const;
                const constness_compat = v_info.is_const and !i_info.is_const;

                break :safe sentinels_match and (constness_match or constness_compat);
            };

            if (safe and lt == .heap) {
                return .{ .value = @as(Value, input), .used = true };
            }

            const output = try ally.alloc(u8, input.len + @intFromBool(v_info.sentinel != null));
            std.mem.copyForwards(u8, output, input);

            if (v_info.sentinel) |s| {
                const sentinel_char = @as(*const u8, @ptrCast(s)).*;
                output[input.len] = sentinel_char;

                return .{
                    .value = output[0..input.len :sentinel_char],
                    .used = false,
                };
            }

            return .{ .value = output, .used = false };
        }

        const Child = std.meta.Child(Value);
    };
}
