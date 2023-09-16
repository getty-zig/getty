const std = @import("std");

const free = @import("../../free.zig").free;
const StringLifetime = @import("../../lifetime.zig").StringLifetime;
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

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            if (ally == null) {
                return error.MissingAllocator;
            }

            const a = ally.?;

            var list = std.ArrayList(Child).init(a);
            errdefer free(a, Deserializer, list);

            while (try seq.nextElement(a, Child)) |elem| {
                try list.append(elem);
            }

            if (@typeInfo(Value).Pointer.sentinel) |s| {
                const sentinel_char = @as(*const Child, @ptrCast(s)).*;
                return try list.toOwnedSliceSentinel(sentinel_char);
            }

            return try list.toOwnedSlice();
        }

        fn visitString(
            _: Self,
            ally: ?std.mem.Allocator,
            comptime Deserializer: type,
            input: anytype,
            lifetime: StringLifetime,
        ) Deserializer.Err!Value {
            if (Child != u8) {
                return error.InvalidType;
            }

            const v_info = @typeInfo(Value).Pointer;

            {
                const i_info = @typeInfo(@TypeOf(input)).Pointer;

                const sentinels_match = (v_info.sentinel == null) == (i_info.sentinel == null);
                const constness_match = v_info.is_const == i_info.is_const;
                const constness_compat = v_info.is_const and !i_info.is_const;

                if (lifetime == .heap and sentinels_match and (constness_match or constness_compat)) {
                    return @as(Value, input);
                }
            }

            if (ally == null) {
                return error.MissingAllocator;
            }

            const output = try ally.?.alloc(u8, input.len + @intFromBool(v_info.sentinel != null));
            std.mem.copy(u8, output, input);

            if (v_info.sentinel) |s| {
                const sentinel_char = @as(*const u8, @ptrCast(s)).*;
                output[input.len] = sentinel_char;
                return output[0..input.len :sentinel_char];
            }

            return output;
        }

        const Child = std.meta.Child(Value);
    };
}
