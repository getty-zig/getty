/// A generic error set for `getty.Serializer` implementations.
///
/// This error set must always be included in a `getty.Serializer`
/// implementation's error set.
pub const Error = error{
    /// A union variant marked as skipped was serialized.
    UnknownVariant,
};
