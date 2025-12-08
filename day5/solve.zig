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
    var readingRanges: bool = true;
    var rangeList: std.ArrayList([2]u64) = .empty;
    defer rangeList.deinit(allocator);
    var freshCount: u64 = 0;


    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (std.mem.eql(u8, line, "")) {
            readingRanges = false;
            std.mem.sort([2]u64, rangeList.items, {}, compareRanges);
            continue;
        }

        if (readingRanges) {
            try rangeList.append(allocator, try splitRange(line));
        } else {
            if (ingredientIsFresh(rangeList, try parseInt(u64, line, 0))) {
                freshCount += 1;
            }
        }
    }

    printRanges(rangeList);
    print("Total fresh ingredients: {d}\n", .{freshCount});
}

fn ingredientIsFresh(rangeList: std.ArrayList([2]u64), ingredient: u64) bool {
    for (rangeList.items) |range| {
        if (ingredient < range[0]) {
            return false;
        }
        if (ingredient >= range[0] and ingredient <= range[1]) {
            return true;
        }
    }
    return false;
}

fn splitRange(range: []u8) ![2]u64 {
    var sequence = std.mem.tokenizeScalar(u8, range, '-');
    var output: [2]u64 = undefined;
    var index: u4 = 0;

    while (sequence.next()) |value| {
        output[index] = try parseInt(u64, value, 0);
        index += 1;
    }

    return output;
}

fn printRanges(rangeList: std.ArrayList([2]u64)) void {
    for (rangeList.items) |range| {
        for (range) |item| {
            print("{} - ", .{item});
        }
        print("\n", .{});
    }
}

fn compareRanges(_: void, left: [2]u64, right: [2]u64) bool {
    return left[0] < right[0];
}
