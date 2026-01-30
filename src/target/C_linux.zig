const std = @import("std");
const lib = @import("lego");
const fmt = @import("C_linux_fmt.zig");

const Writer = std.Io.Writer;
const HashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Int = lib.Int;
const Graph = lib.Graph;
const Root = lib.Root;
const Function = lib.Function;
const StringList = lib.StringList;
const StringExtraList = lib.StringExtraList;
const Block = lib.Block;
const Inst = lib.Inst;

fn HashSet(comptime T: type) type {
    return HashMap(T, void);
}

pub fn emit(writer: *Writer, gpa: Allocator, graph: Graph) !void {
    try writer.print("// Start of file\n", .{});
    try writer.print("#include <stdint.h>\n", .{});
    try writer.print("\n", .{});

    try emitRoot(writer, graph, graph.root);
    try writer.print("\n", .{});

    for (graph.functions) |function| {
        try emitFunction(writer, gpa, graph, function);
        try writer.print("\n", .{});
    }

    try writer.flush();
}

fn emitRoot(writer: *Writer, graph: Graph, root: Root) !void {
    try emitRootVarbs(writer, graph, root.varbs);
}

fn emitRootVarbs(writer: *Writer, graph: Graph, varbs: StringExtraList) !void {
    const names = graph.strings[varbs.names..varbs.names+varbs.len];
    const items = graph.locations[varbs.items..varbs.items+varbs.len];
    const extra = graph.constants[varbs.extra..varbs.extra+varbs.len];

    for (names, items, extra) |name, item, con| {
        const typx = graph.typxs[item.typx];

        try writer.print("{f} {s} = {d};\n", .{typx.fmt(graph, fmt), name, con});
    }
}

fn emitFunction(writer: *Writer, gpa: Allocator, graph: Graph, function: Function) !void {
    try writer.print("{f} {{\n", .{function.fmtProto(graph, fmt)});

    try emitFunctionVarbs(writer, graph, function.varbs);
    try emitFunctionBlock(writer, gpa, graph, function.block);

    try writer.print("}}\n", .{});
}

fn emitFunctionVarbs(writer: *Writer, graph: Graph, varbs: StringList) !void {
    const names = graph.strings[varbs.names..varbs.names+varbs.len];
    const items = graph.locations[varbs.items..varbs.items+varbs.len];

    for (names, items) |name, item| {
        const typx = graph.typxs[item.typx];

        try writer.print("\t{f} {s};\n", .{typx.fmt(graph, fmt), name});
    }
}

fn emitFunctionBlock(writer: *Writer, gpa: Allocator, graph: Graph, root: Int) !void {
    var todo = ArrayList(Int).empty;
    var done = HashSet(Int).init(gpa);
    defer todo.deinit(gpa);
    defer done.deinit();

    try todo.append(gpa, root);

    while (todo.pop()) |node| {
        if (done.contains(node)) continue;

        const block = graph.blocks[node];
        const insts = graph.insts[block.idx..block.idx+block.len];

        try writer.print("L{}:\n", .{node});

        for (insts) |inst| {
            try emitInst(writer, graph, inst);
        }

        switch (block.flow) {
            .ret => |v| {
                const location = graph.locations[v];
                try writer.print("\treturn {f};\n", .{location.fmt(graph, fmt)});
            },
            .jmp => |j| {
                try todo.append(gpa, j);
                try writer.print("\tgoto L{d};\n", .{j});
            },
            .jnz => |j| {
                const location = graph.locations[j.cond];
                try todo.append(gpa, j.rhs);
                try todo.append(gpa, j.lhs);
                try writer.print("\tif ({f}) goto L{d}; else goto L{d};\n", .{location.fmt(graph, fmt), j.lhs, j.rhs});
            },
        }

        try done.put(node, {});
    }
}

fn emitInst(writer: *Writer, graph: Graph, inst: Inst) !void {
    switch (inst) {
        .put => |m| {
            const dst = graph.locations[m.dst];
            const src = graph.constants[m.src];

            try writer.print("\t{f} = {d};\n", .{
                dst.fmt(graph, fmt),
                src,
            });
        },
        .get => |m| {
            const dst = graph.locations[m.dst];
            const src = graph.locations[m.src];

            const dtx = graph.typxs[dst.typx];

            try writer.print("\t{f} = *({f} *) {f};\n", .{
                dst.fmt(graph, fmt),
                dtx.fmt(graph, fmt),
                src.fmt(graph, fmt),
            });
        },
        .set => |m| {
            const dst = graph.locations[m.dst];
            const src = graph.locations[m.src];

            const dtx = graph.typxs[dst.typx];

            try writer.print("\t*({f} *) {f} = {f};\n", .{
                dtx.fmt(graph, fmt),
                dst.fmt(graph, fmt),
                src.fmt(graph, fmt),
            });
        },
        .add, .sub, .mul, .div, .eq, .ne, .lt, .gt, .le, .ge => |b| {
            const dst = graph.locations[b.dst];
            const lhs = graph.locations[b.lhs];
            const rhs = graph.locations[b.rhs];

            const op = switch (inst) {
                .add => "+",
                .sub => "-",
                .mul => "*",
                .div => "/",
                .eq => "==",
                .ne => "!=",
                .lt => "<",
                .gt => ">",
                .le => "<=",
                .ge => ">=",
                else => unreachable,
            };

            try writer.print("\t{f} = {f} {s} {f};\n", .{
                dst.fmt(graph, fmt),
                lhs.fmt(graph, fmt),
                op,
                rhs.fmt(graph, fmt),
            });
        },
        .call => |v| {
            const dst = graph.locations[v.dst];
            const src = graph.locations[v.src];
            const args = graph.locations[v.idx..v.idx+v.len];

            try writer.print("\t{f} = {f}(", .{
                dst.fmt(graph, fmt),
                src.fmt(graph, fmt),
            });

            for (args, 1..) |arg, idx| {
                try writer.print("{f}", .{arg.fmt(graph, fmt)});

                if (idx != args.len)
                    try writer.print(",", .{});
            }

            try writer.print(");\n", .{});
        },
    }
}
