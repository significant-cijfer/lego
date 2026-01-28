const std = @import("std");
const lib = @import("lego");

const stdout = std.fs.File.stdout();

const Graph = lib.Graph;

pub fn main() !void {
    const target = @import("target/C_linux.zig");

    var dba = std.heap.DebugAllocator(.{}){};
    const gpa = dba.allocator();

    var graph = Graph{
        .allocator = gpa,
        .functions = .empty,
        .locations = .empty,
        .strings = .empty,
        .blocks = .empty,
        .insts = .empty,
        .typxs = .empty,
        .text = "",
    };
    defer graph.deinit();

    try graph.locations.appendSlice(gpa, &.{
        .{
            .code = .{
                .temp = false,
                .token = 0,
            },
            .typx = 1,
        },
    });

    try graph.strings.appendSlice(gpa, &.{
        "blep",
        "main",
    });

    try graph.blocks.appendSlice(gpa, &.{
        .{
            .idx = 0,
            .len = 1,
            .flow = .{ .ret = 0 },
        },
    });

    try graph.insts.appendSlice(gpa, &.{
        .{ .put = .{ .dst = 0, .src = 103 } },
        //.{ .add = .{ .dst = 0, .lhs = 0, .rhs = 0 } },
        //.{ .set = .{ .dst = 0, .src = 0 } },
    });

    try graph.typxs.appendSlice(gpa, &.{
        .{ .primitive = .{ .bits = 32, .sign = false } },
        .{ .primitive = .{ .bits = 32, .sign = false } },
    });

    try graph.functions.append(gpa, .{
        .ident = 1,
        .proto = .{
            .prms = .{
                .names = 0,
                .items = 0,
                .len = 0,
            },
            .ret = 0,
        },
        .varbs = .{
            .names = 0,
            .items = 0,
            .len = 1,
        },
        .block = 0,
    });

    var buffer: [8192]u8 = undefined;
    var writer = stdout.writer(&buffer);

    try target.emit(&writer.interface, graph);
}
