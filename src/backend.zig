const std = @import("std");
const lib = @import("root.zig");

const Writer = std.Io.Writer;
const Allocator = std.mem.Allocator;

const Graph = lib.Graph;

pub const Target = enum {
    c_linux,
};

pub fn emit(writer: *Writer, gpa: Allocator, graph: Graph, comptime backend: Target) !void {
    const target = switch (backend) {
        .c_linux => @import("target/C_linux.zig"),
    };

    const f = target.Fmt{ .graph = &graph };

    try target.emitHeader(writer);
    try writer.print("\n", .{});

    try target.emitRoot(writer, f, graph.root);
    try writer.print("\n", .{});

    for (graph.functions) |function| {
        try target.emitFunction(writer, gpa, f, function);
        try writer.print("\n", .{});
    }

    try writer.flush();
}
