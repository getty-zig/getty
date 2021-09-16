const std = @import("std");

const interface = @import("../../interface.zig");

pub fn Visitor(comptime Value: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace interface.Visitor(
            *Self,
            Value,
            visitBool,
            visitEnum,
            visitFloat,
            visitInt,
            visitMap,
            visitNull,
            visitSequence,
            visitSlice,
            visitSome,
            visitVoid,
        );

        fn visitBool(self: *Self, comptime Error: type, input: bool) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitEnum(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitFloat(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitInt(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = input;

            @panic("Unsupported");
        }

        fn visitMap(self: *Self, allocator: ?*std.mem.Allocator, mapAccess: anytype) @TypeOf(mapAccess).Error!Value {
            _ = self;

            var map: Value = undefined;

            inline for (std.meta.fields(Value)) |field| {
                if (try mapAccess.nextKey([]const u8)) |key| {
                    defer allocator.?.free(key);

                    // FIXME: Adding the else branch causes a compiler error.
                    if (std.mem.eql(u8, field.name, key)) {
                        @field(map, field.name) = try mapAccess.nextValue(field.field_type);
                        //  ...
                        //} else {
                        //@panic("wrong key");
                    }
                }
            }

            if (try mapAccess.nextKey([]const u8)) |_| {
                @panic("expected end of map, found key");
            }

            return map;
        }

        fn visitNull(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            @panic("Unsupported");
        }

        fn visitSequence(self: *Self, allocator: ?*std.mem.Allocator, seqAccess: anytype) @TypeOf(seqAccess).Error!Value {
            _ = self;
            _ = allocator;

            @panic("Unsupported");
        }

        fn visitSlice(self: *Self, allocator: *std.mem.Allocator, comptime Error: type, input: anytype) Error!Value {
            _ = self;
            _ = allocator;
            _ = input;

            @panic("Unsupported");
        }

        fn visitSome(self: *Self, allocator: ?*std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            _ = self;
            _ = allocator;

            @panic("Unsupported");
        }

        fn visitVoid(self: *Self, comptime Error: type) Error!Value {
            _ = self;

            @panic("Unsupported");
        }
    };
}
