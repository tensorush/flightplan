//! Route waypoint data.

const std = @import("std");

const Self = @This();

pub const Type = enum {
    @"USER WAYPOINT",
    @"INT-VRP",
    AIRPORT,
    INT,
    NDB,
    VOR,

    pub fn fromString(str: []const u8) Type {
        return std.meta.stringToEnum(Type, str).?;
    }

    pub fn toString(self: Type) []const u8 {
        return @tagName(self);
    }
};

/// Waypoint identifier used by route to look it up.
id: []const u8 = undefined,

/// Waypoint type.
type: Type = undefined,

/// Waypoint latitude.
lat: f32 = 0,

/// Waypoint longitude.
lon: f32 = 0,

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    allocator.free(self.id);

    self.* = undefined;
}
