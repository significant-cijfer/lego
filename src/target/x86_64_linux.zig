const std = @import("std");
const lib = @import("lego");

const Writer = std.Io.Writer;

const Graph = lib.Graph;
const Function = lib.Function;

pub fn emit(writer: *Writer, graph: Graph) !void {
    try writer.print("# <Start of file>\n", .{});

    for (graph.functions.items) |function| {
        try emitFunction(writer, function);

        try writer.print("\n", .{});
    }

    try writer.flush();
}

fn emitFunction(writer: *Writer, graph: Graph, function: Function) !void {
    _ = graph;

    try writer.print("{s}:", .{function.name});

    try writer.print("\tpush %rbp\n", .{});
    try writer.print("\tmovq %rsp, %rbp\n", .{});

    try emitFunctionVarbs(writer, graph, function.varbs);

    //try writer.print("movq %rbp, %rsp\n", .{});
    //try writer.print("pop  %rbp\n", .{});
    //try writer.print("ret  %rbp\n", .{});
}

fn emitFunctionVarbs(writer: *Writer, graph: Graph, varbs: StringList(Int)) !void {
    _ = graph;

    for (varbs.keys(), varbs.items()) |name, idx| {
        const location = graph.locations.items[idx];

        try writer.print("\tsubq ??, ??\n", .{});
    }
}
