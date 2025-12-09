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
    var beams: std.AutoHashMap(u8, u64) = std.AutoHashMap(u8, u64).init(allocator);
    defer beams.deinit();

    var initialize: bool = true;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (initialize) {
            for (line, 0..) |spot, index| {
                if (spot == 'S') {
                    try beams.put(@intCast(index), 1);
                }
            }
            initialize = false;
        } else {
            var oldBeams = try beams.clone();
            var iterator = oldBeams.iterator();
            defer oldBeams.deinit();
            beams.clearRetainingCapacity();

            while (iterator.next()) |entry| {
                switch (line[entry.key_ptr.*]) {
                    '^' => {
                        if (entry.key_ptr.* > 0) {
                            const result = try beams.getOrPut(entry.key_ptr.* - 1);
                            if (result.found_existing) {
                                try beams.put(entry.key_ptr.* - 1, result.value_ptr.* + entry.value_ptr.*);
                            } else {
                                result.value_ptr.* = entry.value_ptr.*;
                            }
                        }
                        if (entry.key_ptr.* < line.len) {
                            const result = try beams.getOrPut(entry.key_ptr.* + 1);
                            if (result.found_existing) {
                                try beams.put(entry.key_ptr.* + 1, result.value_ptr.* + entry.value_ptr.*);
                            } else {
                                result.value_ptr.* = entry.value_ptr.*;
                            }
                        }
                    },
                    else => {
                        const result = try beams.getOrPut(entry.key_ptr.*);
                        if (result.found_existing) {
                            try beams.put(entry.key_ptr.*, result.value_ptr.* + entry.value_ptr.*);
                        } else {
                            result.value_ptr.* = entry.value_ptr.*;
                        }

                    }
                }
            }
        }
    }

    var timelines: u64 = 0;
    var iterator = beams.iterator();
    while (iterator.next()) |entry| {
        timelines += entry.value_ptr.*;
    }

    print("Total splits: {d}\n", .{timelines});
}

