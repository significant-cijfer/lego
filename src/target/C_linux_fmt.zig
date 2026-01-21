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
        const proto = cell.proto;

        const names = graph.strings.items[proto.prms.names..proto.prms.names+proto.prms.len];
        const items = graph.typxs.items[proto.prms.items..proto.prms.items+proto.prms.len];
        const ret = graph.typxs.items[proto.ret];

        try writer.print("{f} {s}(", .{ret.fmt(graph, fmt), cell.name});

        for (names, items) |name, typx|
            try writer.print("{f} {s},", .{typx.fmt(graph, fmt), name});

        try writer.print(")", .{});
    }
};

pub const Location = struct {
    graph: Graph,
    cell: lib.Location,

    pub fn format(self: Location, writer: *std.Io.Writer) !void {
        const graph = self.graph;
        const cell = self.cell;
        const code = cell.code;

        if (code.local)
            try writer.print("t{}", .{code.token})
        else
            try writer.print("{s}", .{graph.strings.items[code.token]});
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
