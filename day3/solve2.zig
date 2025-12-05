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
        sumJoltage += getJoltage(std.mem.trim(u8, line, " \n"));
    }

    print("Total sum: {d}\n", .{sumJoltage});
}

fn getJoltage(input: []const u8) u64 {
    const cellSize: u8 = 12;
    var output: [cellSize]u8 = undefined;
    @memset(&output, 0);

    for (input, 0..) |character, i| {
        const remaining = @min(input.len - i, cellSize);
        const digit = character - '0';
        for(cellSize - remaining .. cellSize) |j| {
            if (digit > output[j]) {
                output[j] = digit;
                for (j + 1 .. cellSize) |k| {
                    output[k] = 0;
                }
                break;
            }
        }
    }

    var joltage: u64 = 0;
    for (output, 0..) |digit, i| {
        joltage += digit * std.math.pow(u64, 10, cellSize - (i + 1));
    }

    return joltage;
}
