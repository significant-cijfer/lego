const std = @import("std");
const lib = @import("lego");
const fmt = @import("C_linux_fmt.zig");

const Writer = std.Io.Writer;
const StringList = std.StringArrayHashMapUnmanaged;

const Int = lib.Int;
const Graph = lib.Graph;

pub const Prototype = struct {
    graph: Graph,
    cell: lib.Function,

    pub fn format(self: Prototype, writer: *std.Io.Writer) !void {
        const graph = self.graph;
        const cell = self.cell;

        const ret = graph.typxs.items[cell.proto.ret];

        try writer.print("{f} {s}(", .{ret.fmt(graph, fmt), cell.name});
    }
};

pub const Location = struct {
    graph: Graph,
    cell: lib.Location,

    pub fn format(self: Location, writer: *std.Io.Writer) !void {
        const graph = self.graph;
        const cell = self.cell;

        _ = graph;
        _ = cell;
        _ = writer;
    }
};

pub const Typx = struct {
    graph: Graph,
    cell: lib.Typx,

    pub fn format(self: Typx, writer: *std.Io.Writer) !void {
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
