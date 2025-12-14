const std = @import("std");
const Queue = @import("queue.zig").Queue;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

const testInputFile = @embedFile("test.txt");
const inputFile = @embedFile("input.txt");

const Machine = struct {
    stateBitMask: u16 = 0,
    buttonsBitMasked: []u16 = undefined,

    pub const Self = @This();

    pub fn init(stateBitMask: u16, buttonsBitMasked: []u16) Self {
        return .{
            .stateBitMask = stateBitMask,
            .buttonsBitMasked = buttonsBitMasked,
        };
    }

    pub fn fromString(allocator: std.mem.Allocator, input: []const u8) !Self {
        const state = input[std.mem.indexOfScalar(u8, input, '[').? + 1..std.mem.indexOfScalar(u8, input, ']').?];
        var stateBitMask: u16 = 0;
        for (state, 0..) |light, index| {
            if (light == '#') {
                stateBitMask += @as(u16, 1) << @intCast(index);
            }
        }


        const buttonsCount = std.mem.count(u8, input, "(");
        var buttons = try allocator.alloc(u16, buttonsCount);
        var buttonsIterator = std.mem.tokenizeScalar(u8, input[state.len + 3..], '(');
        var index: usize = 0;
        while (buttonsIterator.next()) |buttonString| : (index += 1) {
            var buttonBitMask: u16 = 0;
            var toggleIterator = std.mem.splitScalar(u8, buttonString[0..std.mem.indexOfScalar(u8, buttonString, ')').?], ',');
            while (toggleIterator.next()) |toggle| {
                buttonBitMask += @as(u16, 1) << try parseInt(u4, toggle, 0);
            }
            buttons[index] = buttonBitMask;
        }

        return Self.init(stateBitMask, buttons);
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        allocator.free(self.buttonsBitMasked);
        self.* = undefined;
    }

    pub fn getMinButtonPresses(self: *const Self, allocator: std.mem.Allocator) !u64 {
        const NextButton = struct {
            button: u16,
            state: u16,
            count: u64,
        };

        var nextButtonQueue = Queue(NextButton, 10000).init();
        for (self.buttonsBitMasked) |button| {
            try nextButtonQueue.enqueue(NextButton {
                .button = button,
                .state = 0,
                .count = 0,
            });
        }

        var minButtonPresses: std.AutoHashMap(u16, u64) = std.AutoHashMap(u16, u64).init(allocator);
        defer minButtonPresses.deinit();
        try minButtonPresses.putNoClobber(0, 0);

        var minToTarget: u64 = std.math.maxInt(u64);
        while (!nextButtonQueue.isEmpty()) {
            const nextButton = try nextButtonQueue.dequeue();
            const nextCount = nextButton.count + 1;
            if (nextCount >= minToTarget) {
                continue;
            }

            const nextState = nextButton.state ^ nextButton.button;
            if (minButtonPresses.get(nextState)) |count| {
                if (nextCount >= count) {
                    continue;
                }
            }

            const result = try minButtonPresses.getOrPut(nextState);
            if (result.found_existing) {
                result.value_ptr.* = @min(nextCount, result.value_ptr.*);
            } else {
                result.value_ptr.* = nextCount;
            }

            if (nextState == self.stateBitMask) {
                minToTarget = nextCount;
            } else {
                for (self.buttonsBitMasked) |button| {
                    if (button == nextButton.button) {
                        continue;
                    }

                    try nextButtonQueue.enqueue(NextButton {
                        .button = button,
                        .state = nextState,
                        .count = nextCount,
                    });
                }
            }
        }

        return minToTarget;
    }
};

pub fn solve(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var minButtonPresses: u64 = 0;
    var inputIterator = std.mem.tokenizeScalar(u8, input, '\n');
    while (inputIterator.next()) |line| {
        var machine = try Machine.fromString(allocator, line);
        defer machine.deinit(allocator);
        minButtonPresses += try machine.getMinButtonPresses(allocator);
    }

    return minButtonPresses;
}

pub fn main() !void {
    const arg: []const u8 = if (std.os.argv.len > 1) std.mem.span(std.os.argv[1]) else "";

    if (!std.mem.eql(u8, arg, "solve")) {
        const input: []const u8 = testInputFile;
        const testResult = try solve(input);
        print("Test result: {any}\n", .{testResult});
    }

    if (!std.mem.eql(u8, arg, "test")) {
        const input: []const u8 = inputFile;
        const result = try solve(input);
        print("Result: {any}\n", .{result});
    }
}
