const std = @import("std");
const lib = @import("lego");
const backend = @import("backend.zig");

const stdout = std.fs.File.stdout();

const Graph = lib.Graph;

pub fn main() !void {
    var dba = std.heap.DebugAllocator(.{}){};
    defer _ = dba.deinit();

    const gpa = dba.allocator();

    const graph = Graph{
        .functions = &.{
            .{
                .ident = 1,
                .proto = .{
                    .prms = .{
                        .names = 2,
                        .items = 2,
                        .len = 2,
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
            .{
                .code = .{
                    .temp = false,
                    .token = 4,
                },
                .typx = 4,
            },
        },
        .constants = &.{
            .{ .limbs = &.{10}, .positive = true },
            .{ .limbs = &.{103}, .positive = true },
            .{ .limbs = &.{105}, .positive = true },
            .{ .limbs = &.{123}, .positive = true },
        },
        .strings = &.{
            "blep",
            "main",
            "argc",
            "argv",
            "X",
        },
        .blocks = &.{
            .{
                .idx = 0,
                .len = 1,
                .flow = .{ .jnz = .{ .cond = 0, .lhs = 1, .rhs = 2 } },
            },
            .{
                .idx = 1,
                .len = 1,
                .flow = .{ .ret = 0 },
            },
            .{
                .idx = 2,
                .len = 1,
                .flow = .{ .ret = 0 },
            },
        },
        .insts = &.{
            .{ .put = .{ .dst = 0, .src = 0 } },
            .{ .put = .{ .dst = 0, .src = 1 } },
            .{ .put = .{ .dst = 0, .src = 2 } },
            //.{ .add = .{ .dst = 0, .lhs = 0, .rhs = 0 } },
            //.{ .set = .{ .dst = 0, .src = 0 } },
        },
        .typxs = &.{
            .{ .primitive = .{ .bits = 32, .sign = false } },
            .{ .primitive = .{ .bits = 32, .sign = false } },
            .{ .primitive = .{ .bits = 32, .sign = false } },
            .{ .primitive = .{ .bits = 32, .sign = false } },
            .{ .primitive = .{ .bits = 64, .sign = true } },
        },
        .root = .{
            .varbs = .{
                .names = 4,
                .items = 1,
                .extra = 3,
                .len = 1
            },
        }
    };

    var buffer: [8192]u8 = undefined;
    var writer = stdout.writer(&buffer);

    try backend.emit(&writer.interface, gpa, graph, .c_linux);
}
