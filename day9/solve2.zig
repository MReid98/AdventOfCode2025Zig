const std = @import("std");
const ArrayList = std.ArrayList;
const fs = std.fs;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

const NIL: u2 = 0;
const CORNER: u2 = 1;
const WALL: u2 = 2;
const FILL: u2 = 3;

const Tile = struct {
    x: u64 = 0,
    y: u64 = 0,
    originalX: u64,
    originalY: u64,

    pub fn init(x: u64, y: u64) Tile {
        return .{ .originalX = x, .originalY = y };
    }

    pub fn fromString(input: []u8) !Tile {
        var sequence = std.mem.tokenizeScalar(u8, input, ',');
        var index: u8 = 0;
        var tile = Tile.init(0, 0);
        while (sequence.next()) |value| {
            switch (index) {
                0 => tile.originalX = try parseInt(u64, value, 0),
                1 => tile.originalY = try parseInt(u64, value, 0),
                else => {},
            }
            index += 1;
        }

        return tile;
    }

    pub fn sortXAscPtr(_: void, lhs: *Tile, rhs: *Tile) bool {
        return lhs.originalX < rhs.originalX;
    }

    pub fn sortYAscPtr(_: void, lhs: *Tile, rhs: *Tile) bool {
        return lhs.originalY < rhs.originalY;
    }

    pub fn setX(self: *Tile, x: u64) void {
        self.*.x = x;
    }

    pub fn setY(self: *Tile, y: u64) void {
        self.*.y = y;
    }
};

fn shrinkTiles(tiles: *[]Tile) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var ordered: ArrayList(*Tile) = .empty;
    defer ordered.deinit(allocator);

    for (tiles.*) |*tile| {
        try ordered.append(allocator, tile);
    }

    std.mem.sort(*Tile, ordered.items, {}, Tile.sortXAscPtr);

    var current: u64 = 0;
    var lastOriginal: u64 = ordered.items[0].originalX;
    for (ordered.items) |tile| {
        if (tile.*.originalX == lastOriginal + 1) {
            current += 1;
        } else if (tile.*.originalX > lastOriginal) {
            current += 2;
        }

        tile.*.setX(current);
        lastOriginal = tile.originalX;
    }

    const maxX = current;
    std.mem.sort(*Tile, ordered.items, {}, Tile.sortYAscPtr);

    current = 0;
    lastOriginal = ordered.items[0].originalY;
    for (ordered.items) |tile| {
        if (tile.*.originalY == lastOriginal + 1) {
            current += 1;
        } else if (tile.*.originalY > lastOriginal) {
            current += 2;
        }

        tile.*.setY(current);
        lastOriginal = tile.originalY;
    }

    return .{maxX, current};
}

fn computeMaxRectDiagonalCorners(corners: []Tile, nilMap: std.AutoHashMap(u64, ArrayList([2]u64))) u64 {
    var max_area: u64 = 0;

    for (corners, 0..) |a, i| {
        for (corners[i+1..]) |b| {
            const minOriginalX = @min(a.originalX, b.originalX);
            const minX = @min(a.x, b.x);
            const maxOriginalX = @max(a.originalX, b.originalX);
            const maxX = @max(a.x, b.x);
            const minOriginalY = @min(a.originalY, b.originalY);
            const minY = @min(a.y, b.y);
            const maxOriginalY = @max(a.originalY, b.originalY);
            const maxY = @max(a.y, b.y);

            const area = (1 + maxOriginalX - minOriginalX) * (1 + maxOriginalY - minOriginalY);

            if (area > max_area and isFilledRect(minX, minY, maxX, maxY, nilMap)) {
                max_area = area;
            }
        }
    }

    return max_area;
}

fn isFilledRect(x1: u64, y1: u64, x2: u64, y2: u64, nilMap: std.AutoHashMap(u64, ArrayList([2]u64))) bool {
    for (x1..x2 + 1) |x| {
        const ranges = nilMap.getEntry(x).?.value_ptr.*.items;
        for (ranges) |range| {
            if ((range[0] >= y1 and range[0] <= y2) or (range[1] >= y1 and range[1] <= y2) or (range[0] <= y1 and range[1] >= y2)) {
                return false;
            }
        }
    }
    return true;
}

fn drawBorders(floor: *[][]u2, tiles: []Tile) void {
    for (tiles, 0..) |tile, index| {
        const nextTile = switch (index >= tiles.len - 1) {
            true => tiles[0],
            false => tiles[index + 1],
        };
        floor.*[tile.x][tile.y] = CORNER;
        floor.*[nextTile.x][nextTile.y] = CORNER;

        if (tile.y + 1 < nextTile.y) {
            for (tile.y + 1..nextTile.y) |yIndex| {
                floor.*[tile.x][yIndex] = WALL;
            }
        } else if (nextTile.y + 1 < tile.y) {
            for (nextTile.y + 1..tile.y) |yIndex| {
                floor.*[tile.x][yIndex] = WALL;
            }
        } else if (tile.x + 1 < nextTile.x) {
            for (tile.x + 1..nextTile.x) |xIndex| {
                floor.*[xIndex][tile.y] = WALL;
            }
        } else if (nextTile.x + 1 < tile.x) {
            for (nextTile.x + 1..tile.x) |xIndex| {
                floor.*[xIndex][tile.y] = WALL;
            }
        }
    }
}

fn scanlineFill(floor: *[][]u2) void {
    for (floor.*, 0..) |*row, i| {
        var on: bool = false;
        var cornerFound: bool = false;
        var cornerUp: bool = false;
        for (row.*, 0..) |*tile, j| {
            if (!cornerFound) {
                if (on) {
                    if (tile.* == NIL) {
                        tile.* = FILL;
                    } else if (tile.* == WALL) {
                        on = false;
                    } else if (tile.* == CORNER) {
                        cornerFound = true;
                        if (i == 0 or floor.*[i-1][j] == WALL) {
                            cornerUp = false;
                        }
                        else {
                            cornerUp = true;
                        }
                    }
                } else {
                    if (tile.* == WALL) {
                        on = true;
                    } else if (tile.* == CORNER) {
                        cornerFound = true;
                        if (i == 0 or floor.*[i-1][j] == WALL) {
                            cornerUp = true;
                        } else {
                            cornerUp = false;
                        }
                    }
                }
            } else {
                if (tile.* == CORNER) {
                    cornerFound = false;
                    if (i == 0 or floor.*[i-1][j] == WALL) {
                        on = !cornerUp;
                    } else {
                        on = cornerUp;
                    }
                }
            }
        }
    }
}

fn getNilMap(allocator: std.mem.Allocator, floor: [][]u2) !std.AutoHashMap(u64, ArrayList([2]u64)) {
    var nilMap = std.AutoHashMap(u64, ArrayList([2]u64)).init(allocator);

    for (floor, 0..) |row, x| {
        var foundNil: bool = false;
        var nilStart: u64 = 0;
        try nilMap.putNoClobber(x, .empty);
        for (row, 0..) |tile, y| {
            if (foundNil) {
                if (tile != NIL or y >= row.len - 1) {
                    foundNil = false;
                    const range: [2]u64 = .{nilStart, if (y >= row.len - 1) y else y - 1};
                    const gpr = try nilMap.getOrPut(x);
                    if (gpr.found_existing) {
                        try gpr.value_ptr.*.append(allocator, range);
                    } else {
                        unreachable;
                    }
                }
            } else {
                if (tile == NIL) {
                    foundNil = true;
                    nilStart = y;
                    if (y >= row.len - 1) {
                        const range: [2]u64 = .{y, y};
                        const gpr = try nilMap.getOrPut(x);
                        if (gpr.found_existing) {
                            try gpr.value_ptr.*.append(allocator, range);
                        } else {
                            unreachable;
                        }
                    }
                }
            }
        }
    }

    return nilMap;
}

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
        const tile: *Tile = try allocator.create(Tile);
        tile.* = try Tile.fromString(line);
        try tiles.append(allocator, tile.*);
    }

    const maxXY: [2]u64 = try shrinkTiles(&tiles.items);

    var floor = try allocator.alloc([]u2, maxXY[0] + 2);
    defer allocator.free(floor);

    for (floor) |*row| {
        row.* = try allocator.alloc(u2, maxXY[1] + 2);
        for (row.*) |*tile| {
            tile.* = NIL;
        }
    }

    drawBorders(&floor, tiles.items);

    scanlineFill(&floor);

    var nilMap: std.AutoHashMap(u64, ArrayList([2]u64)) = try getNilMap(allocator, floor);
    defer nilMap.deinit();

    const maxArea = computeMaxRectDiagonalCorners(tiles.items, nilMap);

    print("Max tile area: {}\n", .{ maxArea });
}

fn printNilMap(nilMap: std.AutoHashMap(u64, ArrayList([2]u64))) void {
    var iterator = nilMap.iterator();
    while (iterator.next()) |entry| {
        print("{}:", .{entry.key_ptr.*});
        for (entry.value_ptr.*.items) |range| {
            print(" {}-{}", .{range[0], range[1]});
        }
        print("\n", .{});
    }
}

fn printFloor(floor: [][]u2, x1: u64, y1: u64, x2: u64, y2: u64) !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    var prints: u64 = 0;

    for (y1..y2 + 1) |y| {
        for (x1..x2 + 1) |x| {
            if (prints >= 4096) {
                try stdout.flush();
                prints = 0;
            }
            prints += 1;

            if (floor[x][y] == NIL) {
                try stdout.print("{s}", .{"."});
            }
            if (floor[x][y] == CORNER) {
                try stdout.print("{s}", .{"#"});
            }
            if (floor[x][y] == WALL) {
                try stdout.print("{s}", .{"X"});
            }
            if (floor[x][y] == FILL) {
                try stdout.print("{s}", .{"0"});
            }
        }
        try stdout.print("\n", .{});
        prints += 1;
    }
    try stdout.flush();
}
