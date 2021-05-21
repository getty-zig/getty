const std = @import("std");

pub fn serialize(serializer: anytype, v: anytype) @typeInfo(@TypeOf(serializer)).Pointer.child.Error!@typeInfo(@TypeOf(serializer)).Pointer.child.Ok {
    const s = serializer.serializer();

    return switch (@typeInfo(@TypeOf(v))) {
        .Array => try s.serializeBytes(v),
        .Bool => try s.serializeBool(v),
        .Float => try s.serializeFloat(v),
        .ComptimeInt => {
            if (v >= 0 and v <= std.math.maxInt(u21) and std.unicode.utf8ValidCodepoint(v)) {
                try s.serializeChar(v);
            } else {
                try s.serializeInt(v);
            }
        },
        .Int => try s.serializeInt(v),
        .Pointer => try s.serializeStr(v),
        else => @compileError("unsupported serialize value " ++ @typeName(@TypeOf(v))),
    };
}

/// A data format that can serialize any data structure supported by Getty.
///
/// The interface defines the serialization half of the [Getty data model],
/// which is a way to categorize every Zig data structure into one of TODO
/// possible types. Each method of the `Serializer` interface corresponds to
/// one of the types of the data model.
///
/// Implementations of `Serialize` map themselves into this data model by
/// invoking exactly one of the `Serializer` methods.
///
/// The types that make up the Getty data model are:
///
///  - Primitives
///    - bool
///    - iN (where N is any supported signed integer bit-width)
///    - uN (where N is any supported unsigned integer bit-width)
///    - fN (where N is any supported floating-point bit-width)
pub fn Serializer(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime boolFn: fn (context: Context, value: bool) E!O,
    comptime charFn: fn (context: Context, value: comptime_int) E!O,
    comptime intFn: fn (context: Context, value: anytype) E!O,
    comptime floatFn: fn (context: Context, value: anytype) E!O,
    comptime strFn: fn (context: Context, value: anytype) E!O,
    comptime bytesFn: fn (context: Context, value: anytype) E!O,
    comptime seqFn: fn (context: Context, length: usize) E!O,
    comptime elementFn: fn (context: Context, value: anytype) E!O,
) type {
    return struct {
        const Self = @This();

        pub const Ok = O;
        pub const Error = E;

        context: Context,

        /// Serialize a boolean value.
        pub fn serializeBool(self: Self, value: bool) Error!Ok {
            try boolFn(self.context, value);
        }

        /// Serialize a Unicode code point.
        pub fn serializeChar(self: Self, comptime value: comptime_int) Error!Ok {
            return try charFn(self.context, value);
        }

        /// Serialize an integer value.
        pub fn serializeInt(self: Self, value: anytype) Error!Ok {
            return try intFn(self.context, value);
        }

        /// Serialize a float value.
        pub fn serializeFloat(self: Self, value: anytype) Error!Ok {
            try floatFn(self.context, value);
        }

        /// Serialize a Zig string.
        pub fn serializeStr(self: Self, value: anytype) Error!Ok {
            if (!comptime std.meta.trait.isZigString(@TypeOf(value))) {
                @compileError("expected string, found " ++ @typeName(@TypeOf(value)));
            }

            try strFn(self.context, value);
        }

        /// Serialize a chunk of raw byte data.
        ///
        /// Enables serializers to serialize byte slices more compactly or more
        /// efficiently than other types of slices. If no efficient implementation
        /// is available, a reasonable implementation would be to forward to
        /// `serializeSeq`.
        pub fn serializeBytes(self: Self, value: anytype) Error!Ok {
            if (std.meta.Child(@TypeOf(value)) != u8) {
                @compileError("expected byte array, found " ++ @typeName(@TypeOf(value)));
            }

            try bytesFn(self.context, value);
        }

        /// Begin to serialize a variably sized sequence. This call must be
        /// followed by zero or more calls to `serializeElement`, then a call to
        /// `end`.
        ///
        /// The argument is the number of elements in the sequence, which may or may
        /// not be computable before the sequence is iterated. Some serializers only
        /// support sequences whose length is known up front.
        pub fn serializeSeq(self: Self, length: usize) Error!Ok {
            try seqFn(self.context, length);
        }

        pub fn serializeElement(self: Self, value: anytype) Error!Ok {
            try elementFn(self.context, value);
        }
    };
}

const json = @import("json.zig");

const eql = std.mem.eql;
const expect = std.testing.expect;
const testing_allocator = std.testing.allocator;

test "Serialize - bool" {
    var t = try json.toString(testing_allocator, true);
    defer testing_allocator.free(t);
    var f = try json.toString(testing_allocator, false);
    defer testing_allocator.free(f);

    try expect(eql(u8, t, "true"));
    try expect(eql(u8, f, "false"));
}

test "Serialize - integer" {
    const types = [_]type{
        i8, i16, i32, i64,
        u8, u16, u32, u64,
    };

    inline for (types) |T| {
        const max = std.math.maxInt(T);
        const min = std.math.minInt(T);

        var max_buf: [20]u8 = undefined;
        var min_buf: [20]u8 = undefined;
        const max_expected = std.fmt.bufPrint(&max_buf, "{}", .{max}) catch unreachable;
        const min_expected = std.fmt.bufPrint(&min_buf, "{}", .{min}) catch unreachable;

        const max_encoded = try json.toString(testing_allocator, @as(T, max));
        defer testing_allocator.free(max_encoded);
        const min_encoded = try json.toString(testing_allocator, @as(T, min));
        defer testing_allocator.free(min_encoded);

        try expect(eql(u8, max_encoded, max_expected));
        try expect(eql(u8, min_encoded, min_expected));
    }
}

test "Serialize - Unicode code point" {
    comptime var bits = 1;
    inline while (bits < 21) : (bits += 1) {
        const Unsigned = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = bits } });

        inline for (&[_]type{Unsigned}) |T| {
            const max = std.math.maxInt(T);
            const min = std.math.minInt(T);

            var max_buf: [std.unicode.utf8CodepointSequenceLength(max) catch unreachable]u8 = undefined;
            _ = std.unicode.utf8Encode(max, &max_buf) catch unreachable;
            var max_expected = std.ArrayList(u8).init(testing_allocator);
            defer max_expected.deinit();
            try max_expected.append('"');
            try max_expected.appendSlice(&max_buf);
            try max_expected.append('"');

            var min_buf: [std.unicode.utf8CodepointSequenceLength(min) catch unreachable]u8 = undefined;
            _ = std.unicode.utf8Encode(min, &min_buf) catch unreachable;
            var min_expected = std.ArrayList(u8).init(testing_allocator);
            defer min_expected.deinit();
            try min_expected.append('"');
            try min_expected.appendSlice(&min_buf);
            try min_expected.append('"');

            const max_encoded = try json.toString(testing_allocator, max);
            defer testing_allocator.free(max_encoded);
            const min_encoded = try json.toString(testing_allocator, min);
            defer testing_allocator.free(min_encoded);

            try expect(eql(u8, max_encoded, max_expected.items));
            try expect(eql(u8, min_encoded, min_expected.items));
        }
    }
}
