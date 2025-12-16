const std = @import("std");
const Queue = @import("queue.zig").Queue;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

const testInputFile = @embedFile("test.txt");
const inputFile = @embedFile("input.txt");

const Device = struct {
    name: []const u8,
    links: [][]const u8,

    pub const Self = @This();

    pub fn init(name: []const u8, links: [][]const u8) Self {
        return .{
            .name = name,
            .links = links,
        };
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) !void {
        try allocator.free(self.links);
        self.* = undefined;
    }

    pub fn fromString(allocator: std.mem.Allocator, input: []const u8) !Self {
        const name = input[0..3];
        const linkSection = input[5..];
        const linkCount = std.mem.count(u8, linkSection, " ") + 1;
        const links: [][]const u8 = try allocator.alloc([]const u8, linkCount);

        var linksIterator = std.mem.tokenizeScalar(u8, linkSection, ' ');
        var linkIndex: usize = 0;

        while (linksIterator.next()) |link| : (linkIndex += 1) {
            links[linkIndex] = link;
        }

        return Self.init(name, links);
    }
};

fn getDevices(allocator: std.mem.Allocator, input: []const u8) !std.StringHashMap(Device) {
    var map: std.StringHashMap(Device) = std.StringHashMap(Device).init(allocator);
    var inputIterator = std.mem.tokenizeScalar(u8, input, '\n');
    while (inputIterator.next()) |line| {
        const device: Device = try Device.fromString(allocator, line);
        try map.putNoClobber(device.name, device);
    }
    return map;
}

fn findPaths(map: std.StringHashMap(Device), start: []const u8, end: []const u8) u64 {
    if (std.mem.eql(u8, start, end)) {
        return 0;
    }

    const first = if(map.getEntry(start)) |entry| entry.value_ptr.* else {
        return 0;
    };

    var ends: u64 = 0;
    for (first.links) |link| {
        if (std.mem.eql(u8, link, end)) {
            return 1;
        }

        ends += findPaths(map, link, end);
    }

    return ends;
}

pub fn solve(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const start: []const u8 = "you";
    const end: []const u8 = "out";

    var map: std.StringHashMap(Device) = try getDevices(allocator, input);
    defer map.deinit();

    return findPaths(map, start, end);
}

pub fn main() !void {
    const arg: []const u8 = if (std.os.argv.len > 1) std.mem.span(std.os.argv[1]) else "";

    if (!std.mem.eql(u8, arg, "solve")) {
        const input: []const u8 = testInputFile;
        const testResult = try solve(input);
        print("Test result: {any}\n", .{testResult});
    }

    if (!std.mem.eql(u8, arg, "test")) {
        const input: []const u8 = inputFile;
        const result = try solve(input);
        print("Result: {any}\n", .{result});
    }
}
