//! Destination represents information about the destination portion of a flight
//! plan, such as the destination airport, arrival, approach, etc.

const std = @import("std");

const Runway = @import("Runway.zig");

const Self = @This();

/// Destination waypoint ID. This waypoint must be present in the waypoints map
/// on a flight plan for more information such as lat/lon. This doesn't have to
/// be an airport, this can be a VOR or another NAVAID.
id: []const u8,

/// Destination runway. While this can be set for any identifier, note that
/// a runway is non-sensical for a non-airport identifier.
runway_opt: ?Runway = null,

/// Name of the STAR used for arrival (if any).
star_opt: ?[]const u8 = null,

/// Name of the approach used for arrival (if any). The recommended format
/// is the ARINC 424-18 format, such as LOCD, I26L, etc.
approach_opt: ?[]const u8 = null,

/// Name of the arrival transition (if any).
star_transition_opt: ?[]const u8 = null,

/// Name of the arrival transition (if any).
approach_transition_opt: ?[]const u8 = null,

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    allocator.free(self.id);

    if (self.star_opt) |star| allocator.free(star);
    if (self.approach_opt) |approach| allocator.free(approach);
    if (self.star_transition_opt) |star_transition| allocator.free(star_transition);
    if (self.approach_transition_opt) |approach_transition| allocator.free(approach_transition);

    self.* = undefined;
}
