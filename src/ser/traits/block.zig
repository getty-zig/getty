const std = @import("std");

/// Checks whether `T` contains a serialization block.
pub fn has_sb(
    /// A type to check.
    comptime T: type,
) bool {
    comptime {
        const is_enum = @typeInfo(T) == .Enum;
        const is_struct = @typeInfo(T) == .Struct and !@typeInfo(T).Struct.is_tuple;
        const is_union = @typeInfo(T) == .Union;

        return (is_enum or is_struct or is_union) and @hasDecl(T, "getty.sb");
    }
}
