const std = @import("std");
const lib = @import("lego");

const stderr = std.fs.File.stderr();

const Graph = lib.Graph;

pub fn main() !void {

//}
//
//// This test only exists to force the compiler to fully check all files
//test "Empty Graph (x86-64 linux)" {

    const target = @import("target/C_linux.zig");

    //const gpa = std.testing.allocator;
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

    try graph.locations.appendSlice(gpa, &.{
        .{
            .code = .{
                .local = true,
                .token = 0,
            },
            .typx = 1,
        },
    });

    try graph.blocks.appendSlice(gpa, &.{
        .{
            .idx = 0,
            .len = 0,
            .flow = .{ .ret = 0 },
        },
    });

    try graph.typxs.appendSlice(gpa, &.{
        .{ .primitive = .{ .bits = 32, .sign = false } },
        .{ .primitive = .{ .bits = 32, .sign = false } },
    });

    try graph.functions.append(gpa, .{
        .name = "bleh",
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
            .len = 0,
        },
        .block = 0,
    });

    var buffer: [8192]u8 = undefined;
    var writer = stderr.writer(&buffer);

    try target.emit(&writer.interface, graph);
}
