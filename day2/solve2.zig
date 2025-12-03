const std = @import("std");
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

    var sumInvalids: u64 = 0;

    while (try reader.interface.takeDelimiter(',')) |line| {
        sumInvalids += try sumInvalidIdsInRange(std.mem.trim(u8, line, " \n"));
    }

    print("Total sum: {d}\n", .{sumInvalids});
}

fn sumInvalidIdsInRange(input: []const u8) !u64 {
    var sequence = std.mem.tokenizeScalar(u8, input, '-');
    var range: [2]u64 = .{0, 0};
    var pos: u4 = 0;

    while(sequence.next()) |v| {
        range[pos] = try parseInt(u64, v, 0);
        pos += 1;
    }

    var sumInvalids: u64 = 0;

    for (range[0]..range[1]+1) |i| {
        // I got 10 by finding the biggest number in the puzzle input
        var buf: [10]u8 = undefined;
        const strInt: []u8 = try std.fmt.bufPrint(&buf, "{}", .{i});

        for (1..strInt.len / 2) {

        }

        if (std.mem.eql(u8, strInt[0..digits / 2], strInt[digits / 2..strInt.len])) {
            sumInvalids += i;
        }
    }

    return sumInvalids;
}
