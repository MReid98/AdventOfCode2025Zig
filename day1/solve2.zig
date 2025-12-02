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
    var lines: u32 = 0;
    var totalPasses: u32 = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        var passes: u32 = 0;
        lines += 1;
        pos, passes = try turn(pos, line);
        totalPasses += passes;
    }

    print("Total passes: {d}\n", .{totalPasses});
}

fn turn(pos: i32, input: []u8) !struct{i32, u32} {
    const lr: u8 = input[0];

    const sign: i32 = switch(lr) {
        'L' => -1,
        'R' => 1,
        else => 0,
    };

    const rotation = pos + (try parseInt(i32, input[1..], 0) * sign);

    var passes: u32 = @abs(@divTrunc(rotation, 100));
    if (rotation <= 0 and pos > 0) {
        passes += 1;
    }

    try std.testing.expect(sign != 0);

    const newPos = @mod(rotation, 100);

    return .{newPos, @abs(passes)};
}
