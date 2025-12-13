const std = @import("std");
const ArrayList = std.ArrayList;
const fs = std.fs;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

const Tile = struct {
    x: u64,
    y: u64,

    pub fn init(x: u64, y: u64) Tile {
        return Tile {
            .x = x,
            .y = y,
        };
    }

    pub fn fromString(input: []u8) !Tile {
        var sequence = std.mem.tokenizeScalar(u8, input, ',');
        var index: u8 = 0;
        var tile = Tile.init(0, 0);
        while (sequence.next()) |value| {
            switch (index) {
                0 => tile.x = try parseInt(u64, value, 0),
                1 => tile.y = try parseInt(u64, value, 0),
                else => {},
            }
            index += 1;
        }

        return tile;
    }
};

pub fn main() !void {
    // Get filename from cmd args and open the file
    const path_null_terminated: [*:0]u8 = std.os.argv[1];
    const path: [:0]const u8 = std.mem.span(path_null_terminated);

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
 
    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tiles: ArrayList(Tile) = .empty;
    defer tiles.deinit(allocator);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        try tiles.append(allocator, try Tile.fromString(line));
    }

    var maxArea: u64 = 0;
    for (tiles.items, 0..) |a, index| {
        for (tiles.items[index + 1..]) |b| {
            const minX = @min(a.x, b.x);
            const maxX = @max(a.x, b.x);
            const minY = @min(a.y, b.y);
            const maxY = @max(a.y, b.y);
            const area = (1 + maxX - minX) * (1 + maxY - minY);
            maxArea = @max(maxArea, area);
        }
    }

    print("Max tile area: {}\n", .{maxArea});
}

