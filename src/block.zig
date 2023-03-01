/// Checks whether `T` contains a (de)serialization block.
pub fn has_block(
    /// A type to check.
    comptime T: type,
    /// Indicates type type of block is being checked for.
    comptime serde: enum { ser, de },
) bool {
    comptime {
        switch (@typeInfo(T)) {
            .Enum, .Union => {},
            .Struct => |info| if (info.is_tuple) return false,
            else => return false,
        }

        return switch (serde) {
            .ser => @hasDecl(T, "getty.sb"),
            .de => @hasDecl(T, "getty.db"),
        };
    }
}
