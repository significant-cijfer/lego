const std = @import("std");
const lib = @import("lego");
const fmt = @import("C_linux_fmt.zig");

const Writer = std.Io.Writer;
const HashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Int = lib.Int;
const Root = lib.Root;
const Function = lib.Function;
const StringList = lib.StringList;
const StringExtraList = lib.StringExtraList;
const Block = lib.Block;
const Inst = lib.Inst;

pub const Fmt = fmt.Fmt;

fn HashSet(comptime T: type) type {
    return HashMap(T, void);
}

pub fn emitHeader(writer: *Writer) !void {
    try writer.print("// Start of file\n", .{});
    try writer.print("#include <stdint.h>\n", .{});
}

pub fn emitRoot(writer: *Writer, f: Fmt, root: Root) !void {
    try emitRootVarbs(writer, f, root.varbs);
}

fn emitRootVarbs(writer: *Writer, f: Fmt, varbs: StringExtraList) !void {
    const names = f.graph.strings[varbs.names..varbs.names+varbs.len];
    const items = f.graph.locations[varbs.items..varbs.items+varbs.len];
    const extra = f.graph.constants[varbs.extra..varbs.extra+varbs.len];

    for (names, items, extra) |name, item, con| {
        const typx = f.graph.typxs[item.typx];

        try writer.print("{f} {s} = {d};\n", .{f.typ(typx), name, con});
    }
}

pub fn emitFunction(writer: *Writer, gpa: Allocator, f: Fmt, function: Function) !void {
    try writer.print("{f} {{\n", .{f.proto(function)});

    try emitFunctionVarbs(writer, f, function.varbs);
    try emitFunctionBlock(writer, gpa, f, function.block);

    try writer.print("}}\n", .{});
}

fn emitFunctionVarbs(writer: *Writer, f: Fmt, varbs: StringList) !void {
    const names = f.graph.strings[varbs.names..varbs.names+varbs.len];
    const items = f.graph.locations[varbs.items..varbs.items+varbs.len];

    for (names, items) |name, item| {
        const typx = f.graph.typxs[item.typx];

        try writer.print("\t{f} {s};\n", .{f.typ(typx), name});
    }
}

fn emitFunctionBlock(writer: *Writer, gpa: Allocator, f: Fmt, root: Int) !void {
    var todo = ArrayList(Int).empty;
    var done = HashSet(Int).init(gpa);
    defer todo.deinit(gpa);
    defer done.deinit();

    try todo.append(gpa, root);

    while (todo.pop()) |node| {
        if (done.contains(node)) continue;

        const block = f.graph.blocks[node];
        const insts = f.graph.insts[block.idx..block.idx+block.len];

        try writer.print("L{}:\n", .{node});

        for (insts) |inst| {
            try emitInst(writer, f, inst);
        }

        switch (block.flow) {
            .ret => |v| {
                const location = f.graph.locations[v];
                try writer.print("\treturn {f};\n", .{f.loc(location)});
            },
            .jmp => |j| {
                try todo.append(gpa, j);
                try writer.print("\tgoto L{d};\n", .{j});
            },
            .jnz => |j| {
                const location = f.graph.locations[j.cond];
                try todo.append(gpa, j.rhs);
                try todo.append(gpa, j.lhs);
                try writer.print("\tif ({f}) goto L{d}; else goto L{d};\n", .{f.loc(location), j.lhs, j.rhs});
            },
        }

        try done.put(node, {});
    }
}

fn emitInst(writer: *Writer, f: Fmt, inst: Inst) !void {
    switch (inst) {
        .put => |m| {
            const dst = f.graph.locations[m.dst];
            const src = f.graph.constants[m.src];

            try writer.print("\t{f} = {d};\n", .{
                f.loc(dst),
                src,
            });
        },
        .get => |m| {
            const dst = f.graph.locations[m.dst];
            const src = f.graph.locations[m.src];

            const dtx = f.graph.typxs[dst.typx];

            try writer.print("\t{f} = *({f} *) {f};\n", .{
                f.loc(dst),
                f.typ(dtx),
                f.loc(src),
            });
        },
        .set => |m| {
            const dst = f.graph.locations[m.dst];
            const src = f.graph.locations[m.src];

            const dtx = f.graph.typxs[dst.typx];

            try writer.print("\t*({f} *) {f} = {f};\n", .{
                f.typ(dtx),
                f.loc(dst),
                f.loc(src),
            });
        },
        .add, .sub, .mul, .div, .eq, .ne, .lt, .gt, .le, .ge => |b| {
            const dst = f.graph.locations[b.dst];
            const lhs = f.graph.locations[b.lhs];
            const rhs = f.graph.locations[b.rhs];

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
                f.loc(dst),
                f.loc(lhs),
                op,
                f.loc(rhs),
            });
        },
        .call => |v| {
            const dst = f.graph.locations[v.dst];
            const src = f.graph.locations[v.src];
            const args = f.graph.locations[v.idx..v.idx+v.len];

            try writer.print("\t{f} = {f}(", .{
                f.loc(dst),
                f.loc(src),
            });

            for (args, 1..) |arg, idx| {
                try writer.print("{f}", .{f.loc(arg)});

                if (idx != args.len)
                    try writer.print(",", .{});
            }

            try writer.print(");\n", .{});
        },
    }
}
