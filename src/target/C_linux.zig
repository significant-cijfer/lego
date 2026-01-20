const std = @import("std");
const lib = @import("lego");
const fmt = @import("C_linux_fmt.zig");

const Writer = std.Io.Writer;
const ArrayList = std.ArrayList;
const StringSet = std.StringHashMap(void);

const Int = lib.Int;
const Graph = lib.Graph;
const Function = lib.Function;
const StringList = lib.StringList;
const Block = lib.Block;
const Inst = lib.Inst;

pub fn emit(writer: *Writer, graph: Graph) !void {
    try writer.print("# <Start of file>\n", .{});

    for (graph.functions.items) |function| {
        try emitFunction(writer, graph, function);

        try writer.print("\n", .{});
    }

    try writer.flush();
}

fn emitFunction(writer: *Writer, graph: Graph, function: Function) !void {
    try writer.print("{f} {{\n", .{function.fmtProto(graph, fmt)});

    try emitFunctionVarbs(writer, graph, function.varbs);
    try emitFunctionBlock(writer, graph, function.block);

    try writer.print("}}\n", .{});
}

fn emitFunctionVarbs(writer: *Writer, graph: Graph, varbs: StringList) !void {
    const items = graph.locations.items[varbs.items..varbs.items+varbs.len];
    var size: Int = 0;

    for (items) |item| {
        const typx = graph.typxs.items[item.typx];
        size += typx.size(graph);
    }

    try writer.print("\tchar data[{d}];\n", .{size});
}

fn emitFunctionBlock(writer: *Writer, graph: Graph, root: Int) !void {
    const gpa = graph.allocator;

    var todo = ArrayList(Int).empty;
    var done = StringSet.init(gpa);
    defer todo.deinit(gpa);
    defer done.deinit();

    try todo.append(gpa, root);

    while (todo.pop()) |node| {
        if (done.has(node)) continue;

        const block = graph.blocks.items[node];
        const insts = graph.insts.items[block.idx..block.idx+block.len];

        for (insts) |inst| {
            try emitInst(writer, graph, inst);
        }

        switch (block.flow) {
            .ret => |v| {
                const location = graph.locations.items[v];
                try writer.print("\treturn {f};\n", .{location.fmt(graph, fmt)});
            },
            .jmp => |j| {
                try todo.append(gpa, j);
                try writer.print("\tgoto L{d};\n", .{j});
            },
            .jnz => |j| {
                const location = graph.locations.items[j.cond];
                try todo.append(gpa, j.lhs);
                try todo.append(gpa, j.rhs);
                try writer.print("\t({f}) ? ({{goto L{d};}}) : ({{goto L{d};}})\n", .{location.fmt(graph, fmt), j.lhs, j.rhs});
            },
        }

        try done.append(node);
    }
}

fn emitInst(writer: *Writer, graph: Graph, inst: Inst) !void {
    //try writer.print("\t{f}\n", .{inst.fmt(graph)});
    try writer.print("\t# TODO: inst\n", .{});

    _ = graph;
    _ = inst;
}
