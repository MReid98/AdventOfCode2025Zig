const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const size: u8 = 140;

pub fn main() !void {
    // Get filename from cmd args and open the file
    const path_null_terminated: [*:0]u8 = std.os.argv[1];
    const path: [:0]const u8 = std.mem.span(path_null_terminated);

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    
    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var warehouse: [size][size]bool = undefined;
    var xIndex: u8 = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        for (line, 0..) |spot, yIndex| {
            warehouse[xIndex][yIndex] = switch (spot) {
                '@' => true,
                else => false,
            };
        }
        xIndex += 1;
    }

    var oldCount: u64 = 1;
    var newCount: u64 = 0;
    while (oldCount != newCount) {
        oldCount = newCount;
        newCount += getMoveableRolls(&warehouse);
    }

    print("Total moveable rolls: {d}\n", .{newCount});
}

fn getMoveableRolls (warehouse: *[size][size]bool) u64 {
    var count: u64 = 0;
    for (warehouse, 0..) |row, xIndex| {
        for (row, 0..) |spot, yIndex| {
            if (spot and getAdjacentCount(warehouse.*, @intCast(xIndex), @intCast(yIndex)) < 4) {
                count += 1;
                warehouse.*[xIndex][yIndex] = false;
            }
        }
    }
    return count;
}

fn getAdjacentCount (warehouse: [size][size]bool, xSpot: u8, ySpot: u8) u8 {
    var count: u8 = 0;
    for (if (xSpot <= 0) 0 else xSpot - 1..if (xSpot + 1 >= size) size else xSpot + 2) |xIndex| {
        for (if (ySpot <= 0) 0 else ySpot - 1..if (ySpot + 1 >= size) size else ySpot + 2) |yIndex| {
            if (warehouse[xIndex][yIndex] and (xIndex != xSpot or yIndex != ySpot)) {
                count += 1;
            }
        }
    }
    return count;
}
