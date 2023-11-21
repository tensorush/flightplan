//! Runway information.

const std = @import("std");

const Self = @This();

/// Position is the potential position of runways with matching numbers.
pub const Position = enum {
    L,
    R,
    C,
};

/// Runway relative position.
position_opt: ?Position = null,

/// Runway number.
number: u16,

/// Convert to string. The buffer must be at least 3 characters, otherwise returns an error.
pub fn toString(self: Self, buf: []u8) ![]u8 {
    var position_str: []const u8 = "";
    if (self.position_opt) |position| {
        position_str = @tagName(position);
    }
    return try std.fmt.bufPrint(buf, "{d:0>2}{s}", .{ self.number, position_str });
}

test toString {
    var buf: [6]u8 = undefined;

    var runway = Self{ .number = 25 };
    try std.testing.expectEqualStrings(try runway.toString(buf[0..]), "25");

    runway = .{ .number = 25, .position_opt = .L };
    try std.testing.expectEqualStrings(try runway.toString(buf[0..]), "25L");

    runway = .{ .number = 1, .position_opt = .C };
    try std.testing.expectEqualStrings(try runway.toString(buf[0..]), "01C");

    runway = .{ .number = 679 };
    try std.testing.expectEqualStrings(try runway.toString(buf[0..]), "679");
}
