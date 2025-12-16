const std = @import("std");
const ArrayList = std.ArrayList;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

const testInputFile = @embedFile("test2.txt");
const inputFile = @embedFile("input.txt");
const start: []const u8 = "svr";
const end: [] const u8 = "out";
const needles = [2][]const u8{"fft", "dac"};

const Device = struct {
    name: []const u8,
    links: [][]const u8,
    ends: [4]u64 = [4]u64{0, 0, 0, 0},

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
        const name: []const u8 = input[0..3];
        const linkSection = input[5..];
        const linkCount = std.mem.count(u8, linkSection, " ") + 1;
        const links: [][]const u8 = try allocator.alloc([]const u8, linkCount);

        var linksIterator = std.mem.tokenizeScalar(u8, linkSection, ' ');
        var linkIndex: usize = 0;

        while (linksIterator.next()) |link| : (linkIndex += 1) {
            links[linkIndex] = link[0..3];
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

fn findPaths(map: std.StringHashMap(Device), current: []const u8) [4]u64 {
    if (std.mem.eql(u8, current, end)) {
        return [4]u64{1, 0, 0, 0};
    }

    var first = if(map.getEntry(current)) |entry| entry.value_ptr else {
        return [4]u64{0, 0, 0, 0};
    };

    if (first.ends[0] > 0 or first.ends[1] > 0 or first.ends[2] > 0 or first.ends[3] > 0){
        return first.ends;
    }

    var ends: [4]u64 = .{0, 0, 0, 0};
    var this: usize = 0;
    for (needles, 0..) |needle, index| {
        if (std.mem.eql(u8, needle, current)) {
            this = index + 1;
        }
    }

    for (first.links) |link| {
        const newEnds = findPaths(map, link);
        if (this == 0) {
            ends[0] += newEnds[0];
            ends[1] += newEnds[1];
            ends[2] += newEnds[2];
            ends[3] += newEnds[3];
        } else {
            const other: usize = 3 - this;
            if (newEnds[other] > 0) {
                ends[3] += newEnds[other] + ends[this];
            } else {
                ends[this] += newEnds[0];
            }
        }
    }

    first.ends[0] = ends[0];
    first.ends[1] = ends[1];
    first.ends[2] = ends[2];
    first.ends[3] = ends[3];
    return ends;
}

pub fn solve(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map: std.StringHashMap(Device) = try getDevices(allocator, input);
    defer map.deinit();

    const paths = findPaths(map, start);
    return paths[3];
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
