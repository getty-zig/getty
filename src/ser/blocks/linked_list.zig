//! The default Serialization Block for std.SinglyLinkedList values.

const std = @import("std");

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "linked_list.SinglyLinkedList");
}

pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    var s = try serializer.serializeSeq(value.len());
    const seq = s.seq();
    {
        var iterator = value.first;
        while (iterator) |node| : (iterator = node.next) {
            try seq.serializeElement(node.data);
        }
    }
    return try seq.end();
}
