const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

pub fn main() !void {
    const path_null_terminated: [*:0]u8 = std.os.argv[1];
    const path: [:0]const u8 = std.mem.span(path_null_terminated);

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    
    var file_buffer: [4096]u8 = undefined;
    var reader = file.reader(&file_buffer);

    var pos: i32 = 50;
    var zeros: u32 = 0;
    var lines: u32 = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        lines += 1;
        pos = try turn(pos, line);
        if (pos == 0) {
            zeros += 1;
        }
        print("{s} -- {d} -- {d} -- {d}\n", .{ line, lines, pos, zeros });
    }

    print("Total zeros: {d}\n", .{zeros});
}

fn turn(pos: i32, input: []u8) !i32 {
    const lr: u8 = input[0];

    const sign: i32 = switch(lr) {
        'L' => -1,
        'R' => 1,
        else => 0,
    };

    try std.testing.expect(sign != 0);

    const newPos = @mod((try parseInt(i32, input[1..], 0) * sign) + pos, 100);
    return newPos;
}
