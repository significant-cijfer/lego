const std = @import("std");
const lib = @import("lego");
const fmt = @import("C_linux_fmt.zig");

const Writer = std.Io.Writer;

const Int = lib.Int;
const Graph = lib.Graph;
const Function = lib.Function;
const StringList = lib.StringList;

pub fn emit(writer: *Writer, graph: Graph) !void {
    try writer.print("# <Start of file>\n", .{});

    for (graph.functions.items) |function| {
        try emitFunction(writer, graph, function);

        try writer.print("\n", .{});
    }

    try writer.flush();
}

fn emitFunction(writer: *Writer, graph: Graph, function: Function) !void {
    try writer.print("{f} {{", .{function.fmtProto(graph, fmt)});

    try emitFunctionVarbs(writer, graph, function.varbs);

    //try writer.print("movq %rbp, %rsp\n", .{});
    //try writer.print("pop  %rbp\n", .{});
    //try writer.print("ret  %rbp\n", .{});
}

fn emitFunctionVarbs(writer: *Writer, graph: Graph, varbs: StringList) !void {
    const names = graph.strings.items[varbs.names..varbs.names+varbs.len];
    const items = graph.locations.items[varbs.items..varbs.items+varbs.len];

    for (names, items) |name, location| {
        _ = name;
        _ = location;

        try writer.print("\tsubq ??, ??\n", .{});
    }
}
