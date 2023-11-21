//! Departure represents information about the departure portion of a flight
//! plan, such as the departing airport, runway, procedure, transition, etc.
//!
//! This is just the departure procedure metadata. The route of the DP is
//! expected to still be added manually to the Plan's route field.

const std = @import("std");

const Runway = @import("Runway.zig");

const Self = @This();

/// Departure waypoint ID. This waypoint must be present in the waypoints map
/// on a flight plan for more information such as lat/lon. This doesn't have to
/// be an airport, this can be a VOR or another NAVAID.
id: []const u8,

/// Departure runway. While this can be set for any identifier, note that
/// a runway is non-sensical for a non-airport identifier.
runway_opt: ?Runway = null,

// Name of the SID used for departure (if any)
sid_opt: ?[]const u8 = null,

/// Name of the departure transition (if any). This may be set when sid
/// is null but that makes no sense.
transition_opt: ?[]const u8 = null,

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    allocator.free(self.id);

    if (self.sid_opt) |sid| allocator.free(sid);
    if (self.transition_opt) |transition| allocator.free(transition);

    self.* = undefined;
}
