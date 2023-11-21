//! Root library file that exposes the public API.

const std = @import("std");

pub const fms = @import("fms.zig");
pub const fpl = @import("fpl.zig");
pub const Plan = @import("Plan.zig");
pub const Route = @import("Route.zig");
pub const Runway = @import("Runway.zig");
pub const Waypoint = @import("Waypoint.zig");
pub const Departure = @import("Departure.zig");
pub const Destination = @import("Destination.zig");

pub const Error = error{
    MissingPlan,
    MissingRoute,
    MissingWaypoint,
    UnexpectedEndOfInput,
};

test {
    std.testing.refAllDecls(@This());
}
