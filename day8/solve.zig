const std = @import("std");
const ArrayList = std.ArrayList;
const fs = std.fs;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

const Circuit = struct {
    id: u64,
    boxes: ArrayList(*Box),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, id: u64) !Circuit {
        return Circuit {
            .id = id,
            .boxes = .empty,
            .allocator = allocator,
        };
    }

    pub fn insert(self: *Circuit, point: *Box) !void {
        if (point.*.circuit) |other| {
            if (other.id != self.id) {
                try self.join(other);
            }
            return;
        }

        point.setCircuit(self);
        try self.boxes.append(self.allocator, point);
    }

    pub fn join(self: *Circuit, other: *Circuit) !void {
        for (other.boxes.items) |box| {
            box.setCircuit(self);
        }

        try self.*.boxes.appendSlice(self.allocator, other.*.boxes.items);
        other.boxes.clearAndFree(other.allocator);
    }

    pub fn greaterThan(_: void, lhs: *Circuit, rhs: *Circuit) bool {
        return lhs.boxes.items.len > rhs.boxes.items.len;
    }
};

const Box = struct {
    x: i64,
    y: i64,
    z: i64,
    circuit: ?*Circuit = null,

    pub fn init(x: i64, y: i64, z: i64) Box {
        return Box {
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn distance(self: Box, other: Box) f64 {
        const distanceX: f64 = @floatFromInt(self.x - other.x);
        const distanceY: f64 = @floatFromInt(self.y - other.y);
        const distanceZ: f64 = @floatFromInt(self.z - other.z);
        const sqrDistance: f64 = (distanceX * distanceX) + (distanceY * distanceY) + (distanceZ * distanceZ);
        const out: f64 = @sqrt(sqrDistance);
        return out;
    }

    pub fn setCircuit(self: *Box, circuit: *Circuit) void {
        self.*.circuit = circuit;
    }

    pub fn fromString(input: []u8) !Box {
        var sequence = std.mem.tokenizeScalar(u8, input, ',');
        var index: u8 = 0;
        var point = Box.init(0, 0, 0);
        while (sequence.next()) |value| {
            switch (index) {
                0 => point.x = try parseInt(i64, value, 0),
                1 => point.y = try parseInt(i64, value, 0),
                2 => point.z = try parseInt(i64, value, 0),
                else => {},
            }
            index += 1;
        }
        return point;
    }
};

const Distance = struct {
    start: *Box,
    end: *Box,
    length: f64,

    pub fn init(start: *Box, end: *Box) Distance {
        return Distance {
            .start = start,
            .end = end,
            .length = start.*.distance(end.*),
        };
    }

    pub fn lessThan(_: void, lhs: Distance, rhs: Distance) bool {
        return lhs.length < rhs.length;
    }
};

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

    var boxes: std.ArrayList(*Box) = .empty;
    defer boxes.deinit(allocator);

    var circuits: std.ArrayList(*Circuit) = .empty;
    defer circuits.deinit(allocator);

    var distances: ArrayList(Distance) = .empty;
    defer distances.deinit(allocator);
    const checkNum: u32 = 1000;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const newBox = try allocator.create(Box);
        newBox.* = try Box.fromString(line);
        try boxes.append(allocator, newBox);
    }

    for (boxes.items[0..boxes.items.len - 1], 0..) |box, checkedBoxes| {
        for (boxes.items[checkedBoxes + 1..]) |other| {
            const distance = Distance.init(@constCast(box), @constCast(other));
            try distances.append(allocator, distance);
        }
    }

    std.mem.sort(Distance, distances.items, {}, Distance.lessThan);

    var circuitId: u64 = 0;
    for (distances.items[0..checkNum]) |distance| {
        if (distance.start.circuit) |circuit| {
            try circuit.insert(distance.end);
        } else if (distance.end.circuit) |circuit| {
            try circuit.insert(distance.start);
        } else {
            var newCircuit = try allocator.create(Circuit);
            newCircuit.* = try Circuit.init(allocator, circuitId);
            circuitId += 1;
            try newCircuit.insert(distance.start);
            try newCircuit.insert(distance.end);
            try circuits.append(allocator, newCircuit);
        }
    }

    std.mem.sort(*Circuit, circuits.items, {}, Circuit.greaterThan);

    print("Total product of longest circuits: {d}\n", .{circuits.items[0].boxes.items.len * circuits.items[1].boxes.items.len * circuits.items[2].boxes.items.len});
}
