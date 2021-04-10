const std = @import("std");

pub const RenameStyle = enum {
    camel,
    kebab,
    lower,
    pascal,
    screaming_kebab,
    screaming_snake,
    snake,
    upper,
};

comptime {
    std.testing.refAllDecls(@This());
}
