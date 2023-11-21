//! Route structure represents an ordered list of waypoints (and other
//! potential metadata) for a route in a flight plan.

const std = @import("std");

const Self = @This();

const PointsList = std.ArrayListUnmanaged(Point);

/// Point is a point in a route.
pub const Point = struct {
    pub const Via = union(enum) {
        /// Airport destination
        ADES: void,
        /// Airport departure
        ADEP: void,
        /// Airway
        AWAY: []const u8,
        /// Direct
        DRCT: void,
    };

    /// Identifier of this route point, MUST correspond to a matching
    /// waypoint in the flight plan or most encoding will fail.
    id: []const u8,

    /// The route that this point is via, such as an airway. This is used
    /// by certain formats and ignored by most.
    via_opt: ?Via = null,

    /// Altitude in feet (MSL, AGL, whatever you'd like for your flight
    /// plan and format). This is used by some formats to note the desired
    /// altitude at a given point. This can be zero to note cruising altitude
    /// or field elevation.
    altitude: u16 = 0,

    pub fn deinit(self: *Point, allocator: std.mem.Allocator) void {
        allocator.free(self.id);

        self.* = undefined;
    }
};

/// Route name, human-friendly.
name_opt: ?[]const u8 = null,

/// Ordered list of points in the route. Currently, each value is a string
/// matching the name of a Waypoint. In the future, this will be changed
/// to a rich struct that has more information.
points: PointsList = .{},

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    if (self.name_opt) |name| allocator.free(name);

    for (self.points.items) |*point| {
        point.deinit(allocator);
    }

    self.points.deinit(allocator);

    self.* = undefined;
}
