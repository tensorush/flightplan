//! Garmin & ForeFlight FPL format reading and writing functions.
//!
//! The FPL format does not support departure/arrival procedures.
//! The data it uses is:
//!   * Waypoints
//!   * Route: only identifier per point
//!
//! Reference: https://www8.garmin.com/xmlschemas/FlightPlanv1.xsd

const std = @import("std");
const xml = @import("xml");

const Plan = @import("Plan.zig");
const Route = @import("Route.zig");
const Waypoint = @import("Waypoint.zig");
const Error = @import("flightplan.zig").Error;

/// Read FPL-formatted flight plan.
pub fn read(allocator: std.mem.Allocator, reader: anytype) !Plan {
    var xml_reader = xml.reader(allocator, reader, .{});
    defer xml_reader.deinit();

    while (try xml_reader.next()) |xml_event| {
        switch (xml_event) {
            .element_start => |element_start| {
                if (std.mem.eql(u8, "flight-plan", element_start.name.local)) {
                    var plan = Plan{ .allocator = allocator };
                    while (try xml_reader.next()) |xml_event_child| {
                        switch (xml_event_child) {
                            .element_start => |element_start_child| if (std.mem.eql(u8, "created", element_start_child.name.local)) {
                                plan.created_opt = try allocator.dupe(u8, (try xml_reader.next()).?.element_content.content);
                            } else if (std.mem.eql(u8, "waypoint-table", element_start_child.name.local)) {
                                try readWaypointTable(&plan, &xml_reader);
                            } else if (std.mem.eql(u8, "route", element_start_child.name.local)) {
                                plan.route = try readRoute(plan.allocator, &xml_reader);
                            },
                            else => continue,
                        }
                    }
                    return plan;
                }
            },
            else => continue,
        }
    }
    return Error.MissingPlan;
}

fn readWaypointTable(plan: *Plan, xml_reader: anytype) !void {
    while (try xml_reader.next()) |xml_event| {
        switch (xml_event) {
            .element_start => |element_start| if (std.mem.eql(u8, "waypoint", element_start.name.local)) {
                var waypoint = Waypoint{};
                while (try xml_reader.next()) |xml_event_child| {
                    switch (xml_event_child) {
                        .element_start => |element_start_child| if (std.mem.eql(u8, "identifier", element_start_child.name.local)) {
                            waypoint.id = try plan.allocator.dupe(u8, (try xml_reader.next()).?.element_content.content);
                        } else if (std.mem.eql(u8, "lat", element_start_child.name.local)) {
                            waypoint.lat = try std.fmt.parseFloat(f32, (try xml_reader.next()).?.element_content.content);
                        } else if (std.mem.eql(u8, "lon", element_start_child.name.local)) {
                            waypoint.lon = try std.fmt.parseFloat(f32, (try xml_reader.next()).?.element_content.content);
                        } else if (std.mem.eql(u8, "type", element_start_child.name.local)) {
                            waypoint.type = Waypoint.Type.fromString((try xml_reader.next()).?.element_content.content);
                        },
                        .element_end => |element_end| if (std.mem.eql(u8, "waypoint", element_end.name.local)) break,
                        else => continue,
                    }
                }
                try plan.waypoints.put(plan.allocator, waypoint.id, waypoint);
            },
            .element_end => |element_end| if (std.mem.eql(u8, "waypoint-table", element_end.name.local)) break,
            else => continue,
        }
    }
}

fn readRoute(allocator: std.mem.Allocator, xml_reader: anytype) !Route {
    var route = Route{};

    while (try xml_reader.next()) |xml_event| {
        switch (xml_event) {
            .element_start => |element_start| if (std.mem.eql(u8, "route-name", element_start.name.local)) {
                route.name_opt = try allocator.dupe(u8, (try xml_reader.next()).?.element_content.content);
            } else if (std.mem.eql(u8, "route-point", element_start.name.local)) {
                while (try xml_reader.next()) |xml_event_child| {
                    switch (xml_event_child) {
                        .element_start => |element_start_child| if (std.mem.eql(u8, "waypoint-identifier", element_start_child.name.local)) {
                            try route.points.append(allocator, .{ .id = try allocator.dupe(u8, (try xml_reader.next()).?.element_content.content) });
                        },
                        else => continue,
                    }
                }
            },
            else => continue,
        }
    }

    return route;
}

test "basic reading" {
    const file = try std.fs.cwd().openFile("test/garmin.fpl", .{});
    defer file.close();

    var plan = try read(std.testing.allocator, file.reader());
    defer plan.deinit();

    try std.testing.expectEqualStrings("20211230T22:07:20Z", plan.created_opt.?);
    try std.testing.expectEqual(plan.waypoints.count(), 20);

    try std.testing.expectEqualStrings("KHHR TO KHTH", plan.route.name_opt.?);
    try std.testing.expectEqual(plan.route.points.items.len, 20);

    const waypoint = plan.waypoints.get("KHHR").?;
    try std.testing.expectEqualStrings("KHHR", waypoint.id);
    try std.testing.expect(waypoint.lat > 33.91 and waypoint.lat < 33.93);
    try std.testing.expect(waypoint.lon > -118.336 and waypoint.lon < -118.334);
    try std.testing.expectEqual(waypoint.type, .AIRPORT);
    try std.testing.expectEqualStrings("AIRPORT", waypoint.type.toString());
}

test "error: unexpected end of input" {
    const file = try std.fs.cwd().openFile("test/error_unexpected_end_of_input.fpl", .{});
    defer file.close();

    try std.testing.expectError(Error.UnexpectedEndOfInput, read(std.testing.allocator, file.reader()));
}

test "error: missing flight plan" {
    const file = try std.fs.cwd().openFile("test/error_missing_flight_plan.fpl", .{});
    defer file.close();

    try std.testing.expectError(Error.MissingPlan, read(std.testing.allocator, file.reader()));
}

/// Write FPL-formatted flight plan.
pub fn write(writer: anytype, plan: *const Plan) !void {
    var xml_writer = xml.writer(writer);

    try xml_writer.writeXmlDeclaration("1.0", "utf-8", null);

    const xmlns = "http://www8.garmin.com/xmlschemas/Plan/v1";

    try xml_writer.writeElementStart(.{ .prefix = null, .ns = xmlns, .local = "flight-plan" });
    try xml_writer.writeAttribute(.{ .prefix = null, .ns = xmlns, .local = "xmlns" }, xmlns);

    if (plan.created_opt) |created| {
        try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "created" });
        try xml_writer.writeElementContent(created);
        try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "created" });
    }

    try writeWaypointTable(&xml_writer, plan);
    try writeRoute(&xml_writer, plan);

    try xml_writer.writeElementEnd(.{ .prefix = null, .ns = xmlns, .local = "flight-plan" });
}

fn writeWaypointTable(xml_writer: anytype, plan: *const Plan) !void {
    if (plan.waypoints.count() == 0) {
        return {};
    }

    try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "waypoint-table" });

    var waypoints_iter = plan.waypoints.valueIterator();
    var buf: [128]u8 = undefined;
    while (waypoints_iter.next()) |waypoint| {
        try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "waypoint" });
        try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "identifier" });
        try xml_writer.writeElementContent(waypoint.id);
        try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "identifier" });
        try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "type" });
        try xml_writer.writeElementContent(waypoint.type.toString());
        try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "type" });
        try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "lat" });
        try xml_writer.writeElementContent(try std.fmt.bufPrint(buf[0..], "{d:.6}", .{waypoint.lat}));
        try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "lat" });
        try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "lon" });
        try xml_writer.writeElementContent(try std.fmt.bufPrint(buf[0..], "{d:.6}", .{waypoint.lon}));
        try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "lon" });
        try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "waypoint" });
    }

    try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "waypoint-table" });
}

fn writeRoute(xml_writer: anytype, plan: *const Plan) !void {
    try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "route" });

    if (plan.route.name_opt) |route_name| {
        try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "route-name" });
        try xml_writer.writeElementContent(route_name);
        try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "route-name" });
    }

    for (plan.route.points.items) |point| {
        const waypoint = plan.waypoints.get(point.id) orelse return Error.MissingWaypoint;

        try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "route-point" });
        try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "waypoint-identifier" });
        try xml_writer.writeElementContent(point.id);
        try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "waypoint-identifier" });
        try xml_writer.writeElementStart(.{ .prefix = null, .ns = null, .local = "waypoint-type" });
        try xml_writer.writeElementContent(waypoint.type.toString());
        try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "waypoint-type" });
        try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "route-point" });
    }

    try xml_writer.writeElementEnd(.{ .prefix = null, .ns = null, .local = "route" });
}

test "basic writing" {
    const file = try std.fs.cwd().openFile("test/garmin.fpl", .{});
    defer file.close();

    var plan = try read(std.testing.allocator, file.reader());
    defer plan.deinit();

    var output = std.ArrayList(u8).init(std.testing.allocator);
    defer output.deinit();

    try write(output.writer(), &plan);

    var output_stream = std.io.fixedBufferStream(output.items);
    const output_reader = output_stream.reader();

    var plan_reread = try read(std.testing.allocator, output_reader);
    defer plan_reread.deinit();
}
