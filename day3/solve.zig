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

    var sumJoltage: u64 = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        sumJoltage += try getJoltage(std.mem.trim(u8, line, " \n"));
    }

    print("Total sum: {d}\n", .{sumJoltage});
}

fn getJoltage(input: []const u8) !u64 {
    var maxLeft: u8 = 0;
    var maxRight: u8 = 0;

    for (0..input.len - 1) |i| {
        const digit = try std.fmt.parseInt(u8, input[i..i+1], 10);
        if (digit > maxLeft) {
            maxLeft = digit;
            maxRight = 0;
        } else if (digit > maxRight) {
            maxRight = digit;
        }
    }

    const lastDigit = try std.fmt.parseInt(u8, input[input.len - 1..input.len], 10);
    if (lastDigit > maxRight) {
        maxRight = lastDigit;
    }

    return (10 * maxLeft) + maxRight;
}
