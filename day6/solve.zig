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
    var problems: std.ArrayList(std.ArrayList(u64)) = .empty;
    defer problems.deinit(allocator);

    var totalSum: u64 = 0;
    var readingProblems: bool = true;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        readingProblems = !(std.mem.containsAtLeast(u8, line, 1, "*") or std.mem.containsAtLeast(u8, line, 1, "+"));
        var sequence = std.mem.tokenizeScalar(u8, line, ' ');
        var index: u16 = 0;
        while (sequence.next()) |input| {
            if (std.mem.eql(u8, input, "")) {
                continue;
            }

            if (readingProblems) {
                while (problems.items.len <= index) {
                    const problem: std.ArrayList(u64) = .empty;
                    try problems.append(allocator, problem);
                }

                const number = try parseInt(u64, input, 0);
                try problems.items[index].append(allocator, number);
            } else {
                const multiply: bool = std.mem.eql(u8, input, "*");
                var sum: u64 = if (multiply) 1 else 0;
                for (problems.items[index].items) |number| {
                    sum = if (multiply) sum * number else sum + number;
                }
                totalSum += sum;
            }

            index += 1;
        }
    }

    for (problems.items) |*problem| {
        problem.deinit(allocator);
    }

    print("Total sum: {d}\n", .{totalSum});
}

