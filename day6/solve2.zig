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
    var problems: std.ArrayList([]u8) = .empty;
    defer problems.deinit(allocator);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        try problems.append(allocator, try allocator.dupe(u8, line));
    }

    const operations = problems.pop() orelse return;

    var totalSum: u64 = 0;
    var startIndex: u64 = 0;
    var multiply: bool = false;

    for (operations, 0..) |char, index| {
        switch (char) {
            '*' => {
                multiply = true;
                startIndex = index;
            },
            '+' => {
                multiply = false;
                startIndex = index;
            },
            ' ' => {
                if (index == operations.len - 1 or operations[index + 1] != ' ') {
                    totalSum += getSum(problems.items, multiply, startIndex, index);
                }
            },
            else => {},
        }
    }

    for (problems.items) |problem| {
        allocator.free(problem);
    }

    print("Total sum: {d}\n", .{totalSum});
}

fn getSum(problem: [][]u8, multiply:bool, startIndex: u64, endIndex: u64) u64 {
    var totalSum: u64 = if (multiply) 1 else 0;
    for (startIndex..endIndex + 1) |index| {
        var sum: u64 = 0;
        for (problem) |layer| {
            sum = switch (layer[index]) {
                ' ' => sum,
                else => (sum * 10) + layer[index] - '0',
            };
        }
        if (sum > 0) {
            totalSum = if (multiply) totalSum * sum else totalSum + sum;
        }
    }
    return totalSum;
}
