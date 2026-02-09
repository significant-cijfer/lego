const std = @import("std");
const lib = @import("../root.zig");

const Graph = lib.Graph;

pub const Fmt = struct {
    graph: *const Graph,

    pub fn loc(self: Fmt, l: lib.Location) Location {
        return .{ .graph = self.graph, .cell = l };
    }

    pub fn typ(self: Fmt, t: lib.Location) Typx {
        return .{ .graph = self.graph, .cell = t };
    }

    pub fn con(self: Fmt, c: lib.Constant) Constant {
        return .{ .graph = self.graph, .cell = c };
    }

    pub fn proto(self: Fmt, func: lib.Function) Prototype {
        return .{ .graph = self.graph, .cell = func };
    }

    pub fn ext(self: Fmt, c: lib.Location) Extern {
        return .{ .graph = self.graph, .cell = c };
    }
};

pub const Prototype = struct {
    graph: *const Graph,
    cell: lib.Function,

    pub fn format(self: Prototype, writer: *std.Io.Writer) !void {
        const f = Fmt{ .graph = self.graph };
        const cell = self.cell;
        const proto = cell.proto;

        const ident = f.graph.strings[cell.ident];
        const items = f.graph.locations[proto.prms.items..proto.prms.items+proto.prms.len];
        const ret = f.graph.locations[proto.ret];

        try writer.print("{f} {s}(", .{f.typ(ret), ident});

        for (items, 1..) |item, idx| {
            try writer.print("{f} {f}", .{f.typ(item), f.loc(item)});

            if (idx != proto.prms.len)
                try writer.print(",", .{});
        }

        try writer.print(")", .{});
    }
};

pub const Location = struct {
    graph: *const Graph,
    cell: lib.Location,

    pub fn format(self: Location, writer: *std.Io.Writer) !void {
        const f = Fmt{ .graph = self.graph };
        const cell = self.cell;
        const code = cell.code;

        if (code.temp)
            try writer.print("t{}", .{code.token})
        else
            try writer.print("{s}", .{f.graph.strings[code.token]});
    }
};

pub const Constant = struct {
    graph: *const Graph,
    cell: lib.Constant,

    pub fn format(self: Constant, writer: *std.Io.Writer) !void {
        const f = Fmt{ .graph = self.graph };
        const cell = self.cell;

        switch (cell) {
            .primitive => |p| {
                try writer.print("{d}", .{p});
            },
            .aggregate => |a| {
                const names = f.graph.strings[a.names..a.names+a.len];
                const items = f.graph.constants[a.items..a.items+a.len];

                try writer.print("{{", .{});

                for (names, items, 1..) |name, item, idx| {
                    try writer.print(".{s} = {f}", .{name, f.con(item)});

                    if (idx != items.len)
                        try writer.print(",", .{});
                }

                try writer.print("}}", .{});
            },
        }
    }
};

pub const Typx = struct {
    graph: *const Graph,
    cell: lib.Location,

    pub fn format(self: Typx, writer: *std.Io.Writer) !void {
        const f = Fmt{ .graph = self.graph };
        const cell = self.cell;

        const typx = self.graph.typxs[cell.typx];

        switch (typx) {
            .word => {
                try writer.print("int64_t", .{});
            },
            .pointer => {
                try writer.print("void*", .{});
            },
            .primitive => |p| {
                const sign = if (p.sign) "" else "u";

                try writer.print("{s}int{d}_t", .{sign, p.bits});
            },
            .function => |call| {
                const prms = f.graph.locations[call.prms..call.prms+call.len];
                const ret = f.graph.locations[call.ret];

                try writer.print("{f} (*{f})(", .{f.typ(ret), f.loc(cell)});

                for (prms, 1..) |prm, idx| {
                    try writer.print("{f}", .{f.typ(prm)});

                    if (idx != call.len)
                        try writer.print(",", .{});
                }

                try writer.print(")", .{});
            },
            .aggregate => |a| {
                try writer.print("struct {{", .{});

                for (a.names..a.names+a.len, a.items..a.items+a.len) |name, item| {
                    const loc = lib.Location{
                        .code = .{ .token = @intCast(name), .temp = false },
                        .typx = @intCast(item),
                    };

                    try writer.print("{f} {f};", .{f.typ(loc), f.loc(loc)});
                }

                try writer.print("}}", .{});
            },
        }
    }
};

pub const Extern = struct {
    graph: *const Graph,
    cell: lib.Location,

    pub fn format(self: Extern, writer: *std.Io.Writer) !void {
        const f = Fmt{ .graph = self.graph };
        const cell = self.cell;

        const call = f.graph.typxs[cell.typx].function;
        const prms = f.graph.locations[call.prms..call.prms+call.len];
        const ret = f.graph.locations[call.ret];

        try writer.print("{f} {f}(", .{f.typ(ret), f.loc(cell)});

        for (prms, 1..) |prm, idx| {
            try writer.print("{f}", .{f.typ(prm)});

            if (idx != call.len)
                try writer.print(",", .{});
        }

        try writer.print(")", .{});
    }
};
