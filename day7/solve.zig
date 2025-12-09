const std = @import("std");
const ArrayList = std.ArrayList;
const fs = std.fs;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

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
    var beams: std.AutoHashMap(u8, void) = std.AutoHashMap(u8, void).init(allocator);
    defer beams.deinit();

    var initialize: bool = true;
    var splits: u64 = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (initialize) {
            for (line, 0..) |spot, index| {
                if (spot == 'S') {
                    try beams.put(@intCast(index), {});
                }
            }
            initialize = false;
        } else {
            var oldBeams = try beams.clone();
            var iterator = oldBeams.keyIterator();
            defer oldBeams.deinit();
            beams.clearRetainingCapacity();

            while (iterator.next()) |entry| {
                switch (line[entry.*]) {
                    '^' => {
                        splits += 1;
                        if (entry.* > 0) {
                            try beams.put(entry.* - 1, {});
                        }
                        if (entry.* < line.len) {
                            try beams.put(entry.* + 1, {});
                        }
                    },
                    else => try beams.put(entry.*, {}),
                }
            }
        }
    }

    print("Total splits: {d}\n", .{splits});
}

