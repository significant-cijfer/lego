const std = @import("std");
const lib = @import("lego");

const stdout = std.fs.File.stdout();

const Graph = lib.Graph;

const TargetCLinux = @import("target/C_linux.zig");

pub fn main() !void {
    var dba = std.heap.DebugAllocator(.{}){};
    const gpa = dba.allocator();

    const graph = Graph{
        .functions = &.{
            .{
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
            }
        },
        .locations = &.{
            .{
                .code = .{
                    .temp = false,
                    .token = 0,
                },
                .typx = 1,
            },
        },
        .strings = &.{
            "blep",
            "main",
        },
        .blocks = &.{
            .{
                .idx = 0,
                .len = 1,
                .flow = .{ .ret = 0 },
            },
        },
        .insts = &.{
            .{ .put = .{ .dst = 0, .src = 103 } },
            //.{ .add = .{ .dst = 0, .lhs = 0, .rhs = 0 } },
            //.{ .set = .{ .dst = 0, .src = 0 } },
        },
        .typxs = &.{
            .{ .primitive = .{ .bits = 32, .sign = false } },
            .{ .primitive = .{ .bits = 32, .sign = false } },
        },
    };

    var buffer: [8192]u8 = undefined;
    var writer = stdout.writer(&buffer);

    try TargetCLinux.emit(&writer.interface, gpa, graph);
}
