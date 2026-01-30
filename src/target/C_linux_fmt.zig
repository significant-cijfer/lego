const std = @import("std");
const lib = @import("lego");
const fmt = @import("C_linux_fmt.zig");

const Writer = std.Io.Writer;

const Int = lib.Int;
const Graph = lib.Graph;

pub const Prototype = struct {
    graph: Graph,
    cell: lib.Function,

    pub fn format(self: Prototype, writer: *std.Io.Writer) !void {
        const graph = self.graph;
        const cell = self.cell;
        const proto = cell.proto;

        const ident = graph.strings[cell.ident];
        const names = graph.strings[proto.prms.names..proto.prms.names+proto.prms.len];
        const items = graph.typxs[proto.prms.items..proto.prms.items+proto.prms.len];
        const ret = graph.typxs[proto.ret];

        try writer.print("{f} {s}(", .{ret.fmt(graph, fmt), ident});

        for (names, items, 1..) |name, typx, idx| {
            try writer.print("{f} {s}", .{typx.fmt(graph, fmt), name});

            if (idx != proto.prms.len)
                try writer.print(",", .{});
        }

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

        if (code.temp)
            try writer.print("t{}", .{code.token})
        else
            try writer.print("{s}", .{graph.strings[code.token]});
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
                const sign = if (p.sign) "" else "u";

                try writer.print("{s}int{d}_t", .{sign, p.bits});
            },
            .aggregate => |a| {
                const names = graph.strings[a.names..a.names+a.len];
                const items = graph.typxs[a.items..a.items+a.len];

                try writer.print("struct {{", .{});

                for (names, items) |name, c| try writer.print("{f} {s};", .{c.fmt(graph, fmt), name});

                try writer.print("}}", .{});
            },
        }
    }
};
