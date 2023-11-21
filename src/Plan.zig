//! The primary abstract flight plan structure. This is the structure that
//! various formats decode to an encode from.
//!
//! Note all features of this structure are not supported by all formats.
//! For example, the flight rule field (IFR or VFR) is not used at all by
//! the Garmin or ForeFlight FPL formats, but is used by MSFS 2020 PLN.
//! Formats just ignore information they don't use.

const std = @import("std");

const Route = @import("Route.zig");
const Waypoint = @import("Waypoint.zig");
const Departure = @import("Departure.zig");
const Destination = @import("Destination.zig");

const Self = @This();

/// Flight rule types.
pub const Rule = enum {
    VFR,
    IFR,
};

/// Allocator associated with this Plan. This allocator must be
/// used for all the memory owned by this structure for deinit to work.
allocator: std.mem.Allocator,

/// Flight rule type.
rule: Rule = .IFR,

/// The AIRAC cycle used to create this flight plan, i.e. 2201.
/// See: https://en.wikipedia.org/wiki/Aeronautical_Information_Publication
/// This is expected to be heap-allocated and will be freed on deinit.
airac_opt: ?[]const u8 = null,

/// The timestamp when this flight plan was created. This is expected to
/// be heap-allocated and will be freed on deinit.
/// TODO: some well-known format.
created_opt: ?[]const u8 = null,

/// Departure information.
departure_opt: ?Departure = null,

/// Destination information.
destination_opt: ?Destination = null,

/// Waypoints that are part of the route. These are unordered, they are
/// just the full list of possible waypoints that the route may contain.
waypoints: std.hash_map.StringHashMapUnmanaged(Waypoint) = .{},

/// The flight plan route that may only contain waypoints from the map.
route: Route = .{},

pub fn deinit(self: *Self) void {
    if (self.airac_opt) |airac| self.allocator.free(airac);
    if (self.created_opt) |created| self.allocator.free(created);
    if (self.departure_opt) |*departure| departure.deinit(self.allocator);
    if (self.destination_opt) |*destination| destination.deinit(self.allocator);

    var waypoints_iter = self.waypoints.iterator();
    while (waypoints_iter.next()) |entry| {
        entry.value_ptr.deinit(self.allocator);
    }

    self.waypoints.deinit(self.allocator);
    self.route.deinit(self.allocator);

    self.* = undefined;
}
