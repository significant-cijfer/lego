const std = @import("std");
const Io = std.Io;
const StringHashMap = std.StringHashMap;
const EnumSet = std.EnumSet;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const lego = @import("root.zig");
const Graph = lego.Graph;
const Int = lego.Int;
const Str = lego.Str;

pub const Allocation = struct {
    const Intervals = std.StringArrayHashMap(Interval);
    const Spaces = std.StringHashMap(Space);
    const Pool = std.EnumSet(Register);

    pub fn scan(gpa: Allocator, graph: Graph) !Spaces {
        var spaces = Spaces.init(gpa);
        var active = Intervals.init(gpa);
        var pool = Pool.initFull();

        const ivs = try buildIntervals(gpa, graph);
        for (ivs.keys(), ivs.values()) |_, iv| {
            if (iv.end == null) continue;

            try handleInterval(&spaces, &active, &pool, iv);
        }

        return spaces;
    }

    fn buildIntervals(gpa: Allocator, graph: Graph) !Intervals {
        var map = Intervals.init(gpa);
        var idx: Int = 0;

        for (graph.blocks.items) |block| {
            for (block.insts.items) |inst| {
                switch (inst) {
                    .put => |o| {
                        try updateWrite(&map, o.dst, idx);
                    },
                    .add => |o| {
                        try updateRead(&map, o.lhs, idx);
                        try updateRead(&map, o.rhs, idx);
                        try updateWrite(&map, o.dst, idx);
                    },
                }

                idx += 1;
            }

            switch (block.flow) {
                .jump => {},
                .stop => |v| try updateRead(&map, v, idx),
                .split => |v| try updateRead(&map, v.check, idx),
            }

            idx += 1;
        }

        return map;
    }

    fn updateRead(map: *Intervals, read: Str, idx: Int) !void {
        const item = map.getPtr(read) orelse
            return error.IntervalNotFound;

        item.end = idx;
    }

    fn updateWrite(map: *Intervals, write: Str, idx: Int) !void {
        if (map.contains(write))
            return error.IntervalFound;

        try map.putNoClobber(write, .{
            .location = write,
            .start = idx,
            .end = null,
        });
    }

    fn handleInterval(spaces: *Spaces, active: *Intervals, pool: *Pool, iv: Interval) !void {
        _ = spaces;
        _ = active;
        _ = pool;
        _ = iv;
    }
};

const Register = enum {
    ra,
    rb,
    rc,
    rd,
};

const Space = union(enum) {
    register: Register,
    stack: void,
};

const Interval = struct {
    location: Str,
    start: Int,
    end: ?Int,
};
