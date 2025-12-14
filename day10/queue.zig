const std = @import("std");

pub fn Queue(
    comptime T: type,
    comptime Capacity: usize
) type {
    return struct {
        data: [Capacity]T,
        head: usize = 0,
        tail: usize = 0,
        count: usize = 0,

        pub const Self = @This();

        pub fn init() Self {
            return .{
                .data = undefined,
            };
        }

        pub fn isFull(self: *const Self) bool {
            return self.count == Capacity;
        }

        pub fn isEmpty(self: *const Self) bool {
            return self.count == 0;
        }

        pub fn enqueue(self: *Self, item: T) queueError!void {
            if (self.isFull()) {
                return queueError.QueueFull;
            }

            self.data[self.*.tail] = item;
            self.*.tail = (self.*.tail + 1) % Capacity;
            self.*.count += 1;
        }

        pub fn dequeue(self: *Self) queueError!T {
            if (self.isEmpty()) {
                return queueError.QueueEmpty;
            }

            const item: T = self.data[self.*.head];
            self.*.head = (self.*.head + 1) % Capacity;
            self.*.count -= 1;

            return item;
        }

        pub fn print(self: *const Self) void {
            var current = self.*.head;
            std.debug.print("[ ", .{});
            while (current != self.*.tail) : (current = (current + 1) % Capacity) {
                std.debug.print("{any}, ", .{self.data[current]});
            }
            std.debug.print(" ]\n", .{});
        }

        pub const queueError = error {
            QueueFull,
            QueueEmpty,
        };
    };
}
