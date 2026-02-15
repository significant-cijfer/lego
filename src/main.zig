const std = @import("std");
const lib = @import("lego");

const stdout = std.fs.File.stdout();

const Graph = lib.Graph;
const backend = lib.backend;

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
                        .items = 5,
                        .len = 2,
                    },
                    .ret = 4,
                },
                .varbs = .{
                    .items = 0,
                    .len = 1,
                },
                .block = 0,
            }
        },
        .locations = &.{
            .{ .code = .{ .temp = false, .token = 0 }, .typx = 1 },
            .{ .code = .{ .temp = false, .token = 4 }, .typx = 4 },
            .{ .code = .{ .temp = false, .token = 5 }, .typx = 5 },
            .{ .code = .{ .temp = false, .token = 9 }, .typx = 8 },
            .{ .code = .{ .temp = true, .token = 0 }, .typx = 0 },
            .{ .code = .{ .temp = false, .token = 2 }, .typx = 2 },
            .{ .code = .{ .temp = false, .token = 3 }, .typx = 3 },
            .{ .code = .{ .temp = true, .token = 1 }, .typx = 7 },
            .{ .code = .{ .temp = true, .token = 2 }, .typx = 7 },
            .{ .code = .{ .temp = false, .token = 5 }, .typx = 0 },
        },
        .constants = &.{
            .{ .primitive = .{ .limbs = &.{10}, .positive = true } },
            .{ .primitive = .{ .limbs = &.{103}, .positive = true } },
            .{ .primitive = .{ .limbs = &.{105}, .positive = true } },
            .{ .primitive = .{ .limbs = &.{123}, .positive = true } },
            .{ .aggregate = .{ .names = 6, .items = 5, .len = 2 } },
            .{ .primitive = .{ .limbs = &.{42}, .positive = true } },
            .{ .primitive = .{ .limbs = &.{99}, .positive = true } },
        },
        .strings = &.{
            "blep",
            "main",
            "argc",
            "argv",
            "X",
            "agg",
            "x",
            "y",
            "Z",
            "echo",
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
            .{ .aggregate = {} },
            .{ .primitive = .{ .bits = 16, .sign = true } },
            .{ .primitive = .{ .bits = 64, .sign = false } },
            .{ .function = .{ .prms = 7, .len = 1, .ret = 8 }},
        },
        .typedefs = &.{
            .{ .names = 6, .items = 0, .len = 2 },
        },
        .root = .{
            .imports = .{
                .names = 8,
                .items = 6,
                .len = 1
            },
            .externs = .{
                .items = 3,
                .len = 1,
            },
            .typedefs = .{
                .items = 9,
                .len = 1,
            },
            .varbs = .{
                .items = 1,
                .extra = 3,
                .len = 2
            },
        }
    };

    var buffer: [8192]u8 = undefined;
    var writer = stdout.writer(&buffer);

    try backend.emit(&writer.interface, gpa, graph, .c_linux);
}
