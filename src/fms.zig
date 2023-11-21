//! X-Plane FMS format implementation used by X-Plane 11.10 and later.
//!
//! Reference: https://developer.x-plane.com/article/flightplan-files-v11-fms-file-format/

const std = @import("std");

const fpl = @import("fpl.zig");
const Plan = @import("Plan.zig");
const Route = @import("Route.zig");
const Waypoint = @import("Waypoint.zig");
const Error = @import("flightplan.zig").Error;

pub fn write(writer: anytype, plan: *const Plan) !void {
    try writer.writeAll("I\n");
    try writer.writeAll("1100 Version\n");

    if (plan.airac_opt) |airac| {
        try writer.print("CYCLE {s}\n", .{airac});
    } else {
        var buf: [8]u8 = undefined;
        const num_secs_since_epoch = std.time.epoch.EpochSeconds{ .secs = @intCast(std.time.timestamp()) };
        const num_years_since_2000 = num_secs_since_epoch.getEpochDay().calculateYearDay().year - 2000;
        try writer.print("CYCLE {s}\n", .{try std.fmt.bufPrint(buf[0..], "{d}01", .{num_years_since_2000})});
    }

    if (plan.departure_opt) |departure| {
        try writeDeparture(writer, plan, departure.id);
        try writeDepartureProc(writer, plan);
    } else if (plan.route.points.items.len > 0) {
        const point = &plan.route.points.items[0];
        try writeDeparture(writer, plan, point.id);
    } else {
        return Error.MissingRoute;
    }

    if (plan.destination_opt) |destination| {
        try writeDestination(writer, plan, destination.id);
        try writeDestinationProc(writer, plan);
    } else if (plan.route.points.items.len > 0) {
        const point = &plan.route.points.items[plan.route.points.items.len - 1];
        try writeDestination(writer, plan, point.id);
    } else {
        return Error.MissingRoute;
    }

    try writeRoute(writer, plan);
}

fn writeDeparture(writer: anytype, plan: *const Plan, id: []const u8) !void {
    const waypoint = plan.waypoints.get(id) orelse return Error.MissingWaypoint;

    const prefix = switch (waypoint.type) {
        .AIRPORT => "ADEP",
        else => "DEP",
    };

    try writer.print("{s} {s}\n", .{ prefix, waypoint.id });
}

fn writeDepartureProc(writer: anytype, plan: *const Plan) !void {
    const departure = plan.departure_opt.?;
    var buf: [8]u8 = undefined;
    if (departure.runway_opt) |runway| {
        try writer.print("DEPRWY RW{s}\n", .{try runway.toString(buf[0..])});
    }

    if (departure.sid_opt) |sid| {
        try writer.print("SID {s}\n", .{sid});
        if (departure.transition_opt) |transition| {
            try writer.print("SIDTRANS {s}\n", .{transition});
        }
    }
}

fn writeDestination(writer: anytype, plan: *const Plan, id: []const u8) !void {
    const waypoint = plan.waypoints.get(id) orelse return Error.MissingWaypoint;

    const prefix = switch (waypoint.type) {
        .AIRPORT => "ADES",
        else => "DES",
    };

    try writer.print("{s} {s}\n", .{ prefix, waypoint.id });
}

fn writeDestinationProc(writer: anytype, plan: *const Plan) !void {
    const destination = plan.destination_opt.?;
    var buf: [8]u8 = undefined;

    if (destination.runway_opt) |runway| {
        try writer.print("DESRWY RW{s}\n", .{try runway.toString(buf[0..])});
    }

    if (destination.star_opt) |star| {
        try writer.print("STAR {s}\n", .{star});
        if (destination.star_transition_opt) |transition| {
            try writer.print("STARTRANS {s}\n", .{transition});
        }
    }

    if (destination.approach_opt) |approach| {
        try writer.print("APP {s}\n", .{approach});
        if (destination.approach_transition_opt) |transition| {
            try writer.print("APPTRANS {s}\n", .{transition});
        }
    }
}

fn writeRoute(writer: anytype, plan: *const Plan) !void {
    try writer.print("NUMENR {d}\n", .{plan.route.points.items.len});

    for (plan.route.points.items, 0..) |point, i| {
        const waypoint = plan.waypoints.get(point.id) orelse return Error.MissingWaypoint;

        const waypoint_type: u8 = switch (waypoint.type) {
            .@"USER WAYPOINT" => 28,
            .@"INT-VRP" => 11,
            .AIRPORT => 1,
            .INT => 11,
            .NDB => 2,
            .VOR => 3,
        };

        const via: Route.Point.Via = point.via_opt orelse blk: {
            if (i == 0 and waypoint.type == .AIRPORT) {
                // First route, airport => departure airport
                break :blk .{ .ADEP = {} };
            } else if (i == plan.route.points.items.len - 1 and waypoint.type == .AIRPORT) {
                // Last route, airport => destination airport
                break :blk .{ .ADES = {} };
            } else {
                // Anything else, we go direct
                break :blk .{ .DRCT = {} };
            }
        };

        const via_str = switch (via) {
            .AWAY => |away| away,
            else => |via_tag| @tagName(via_tag),
        };

        try writer.print("{d} {s} {s} {d:.6} {d:.6} {d:.6}\n", .{ waypoint_type, waypoint.id, via_str, point.altitude, waypoint.lat, waypoint.lon });
    }
}

test "read Garmin FPL, write X-Plane 11 FMS" {
    const file = try std.fs.cwd().openFile("test/garmin.fpl", .{});
    defer file.close();

    var plan = try fpl.read(std.testing.allocator, file.reader());
    defer plan.deinit();

    var output = std.ArrayList(u8).init(std.testing.allocator);
    defer output.deinit();

    try write(output.writer(), &plan);

    const exp_file = try std.fs.cwd().openFile("test/garmin2xplane11.fms", .{});
    defer exp_file.close();

    var exp_buf: [1 << 10]u8 = undefined;
    const exp_len = try exp_file.readAll(exp_buf[0..]);

    try std.testing.expectEqualStrings(exp_buf[0..exp_len], output.items);
}
