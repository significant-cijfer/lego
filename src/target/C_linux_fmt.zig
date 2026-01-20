const std = @import("std");
const lib = @import("lego");
const fmt = @import("C_linux_fmt.zig");

const Writer = std.Io.Writer;
const StringList = std.StringArrayHashMapUnmanaged;

const Int = lib.Int;
const Graph = lib.Graph;
const Function = lib.Function;
const Typx = lib.Typx;

pub const Prototype = struct {
    graph: Graph,
    cell: Function,

    pub fn format(self: Prototype, writer: *std.Io.Writer) !void {
        const graph = self.graph;
        const cell = self.cell;

        const ret = graph.typxs.items[cell.proto.ret];

        try writer.print("{f} {s}(", .{ret.fmt(graph, fmt), cell.name});
    }
};

pub const Type = struct {
    graph: Graph,
    cell: Typx,

    pub fn format(self: Type, writer: *std.Io.Writer) !void {
        const graph = self.graph;
        const cell = self.cell;

        switch (cell) {
            .primitive => |p| {
                const sign: u8 = if (p.sign) 'i' else 'u';

                try writer.print("{c}{d}", .{sign, p.bits});
            },
            .aggregate => |a| {
                const names = graph.strings.items[a.names..a.names+a.len];
                const items = graph.typxs.items[a.items..a.items+a.len];

                try writer.print("struct {{", .{});

                for (names, items) |name, c| try writer.print("{s}: {f},", .{name, c.fmt(graph, fmt)});

                try writer.print("}}", .{});
            },
        }
    }
};
