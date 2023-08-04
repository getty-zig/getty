const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for Getty Maps.
pub fn MapAccess(
    /// A namespace that owns the method implementations passed to the `methods` parameter.
    comptime Context: type,
    /// The error set returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing the methods that implementations of `MapAccess` can implement.
    comptime methods: struct {
        nextKeySeed: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value {
                unreachable;
            }
        }.f) = null,

        nextValueSeed: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
                unreachable;
            }
        }.f) = null,

        ////////////////////////////////////////////////////////////////////////
        // Provided methods.
        ////////////////////////////////////////////////////////////////////////

        nextKey: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime K: type) E!?K {
                unreachable;
            }
        }.f) = null,

        nextValue: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime V: type) E!V {
                unreachable;
            }
        }.f) = null,

        /// Returns true if the latest key deserialized by nextKeySeed was
        /// allocated on the heap. Otherwise, false is returned.
        isKeyAllocated: ?fn (Context, comptime K: type) bool = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.MapAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = E;

            pub fn nextKeySeed(self: Self, ally: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
                if (methods.nextKeySeed) |f| {
                    return try f(self.context, ally, seed);
                }

                @compileError("nextKeySeed is not implemented by type: " ++ @typeName(Context));
            }

            pub fn nextValueSeed(self: Self, ally: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
                if (methods.nextValueSeed) |f| {
                    return try f(self.context, ally, seed);
                }

                @compileError("nextValueSeed is not implemented by type: " ++ @typeName(Context));
            }

            //pub fn nextEntrySeed(self: Self, kseed: anytype, vseed: anytype) Error!?std.meta.Tuple(.{ @TypeOf(kseed).Value, @TypeOf(vseed).Value }) {
            //_ = self;
            //}

            pub fn nextKey(self: Self, ally: ?std.mem.Allocator, comptime K: type) Error!?K {
                if (methods.nextKey) |f| {
                    return try f(self.context, ally, K);
                } else {
                    var seed = DefaultSeed(K){};
                    const ds = seed.seed();

                    return try self.nextKeySeed(ally, ds);
                }
            }

            pub fn nextValue(self: Self, ally: ?std.mem.Allocator, comptime V: type) Error!V {
                if (methods.nextValue) |f| {
                    return try f(self.context, ally, V);
                } else {
                    var seed = DefaultSeed(V){};
                    const ds = seed.seed();

                    return try self.nextValueSeed(ally, ds);
                }
            }

            //pub fn nextEntry(self: Self, comptime K: type, comptime V: type) !?std.meta.Tuple(.{ K, V }) {
            //_ = self;
            //}

            pub fn isKeyAllocated(self: Self, comptime K: type) bool {
                if (methods.isKeyAllocated) |f| {
                    return f(self.context, K);
                }

                return @typeInfo(K) == .Pointer;
            }
        };

        /// Returns an interface value.
        pub fn mapAccess(self: Context) @"getty.de.MapAccess" {
            return .{ .context = self };
        }
    };
}
