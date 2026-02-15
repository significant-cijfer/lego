const std = @import("std");
const lib = @import("../root.zig");
const fmt = @import("C_linux_fmt.zig");

const Writer = std.Io.Writer;
const HashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Int = lib.Int;
const Root = lib.Root;
const Function = lib.Function;
const StringList = lib.StringList;
const LocationList = lib.LocationList;
const LocationExtraList = lib.LocationExtraList;
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
    try emitRootTypedefs(writer, f, root.typedefs);
    try emitRootImports(writer, f, root.imports);
    try emitRootExterns(writer, f, root.externs);
    try emitRootVarbs(writer, f, root.varbs);
}

fn emitRootTypedefs(writer: *Writer, f: Fmt, typedefs: LocationList) !void {
    const items = f.graph.locations[typedefs.items..typedefs.items+typedefs.len];

    for (items) |item| {
        try writer.print("{f};\n", .{f.def(item)});
    }
}

fn emitRootImports(writer: *Writer, f: Fmt, imports: StringList) !void {
    for (imports.names..imports.names+imports.len, imports.items..imports.items+imports.len) |name, item| {
        const loc = lib.Location{
            .code = .{ .token = @intCast(name), .temp = false },
            .typx = @intCast(item),
        };

        try writer.print("extern {f} {f};\n", .{f.typ(loc), f.loc(loc)});
    }
}

fn emitRootExterns(writer: *Writer, f: Fmt, externs: LocationList) !void {
    const items = f.graph.locations[externs.items..externs.items+externs.len];

    for (items) |item| {
        try writer.print("extern {f};\n", .{f.ext(item)});
    }
}

fn emitRootVarbs(writer: *Writer, f: Fmt, varbs: LocationExtraList) !void {
    const items = f.graph.locations[varbs.items..varbs.items+varbs.len];
    const extra = f.graph.constants[varbs.extra..varbs.extra+varbs.len];

    for (items, extra) |item, con| {
        if (f.graph.emittable(item.typx))
            try writer.print("{f} {f} = {f};\n", .{f.typ(item), f.loc(item), f.con(con)});
    }
}

pub fn emitFunction(writer: *Writer, gpa: Allocator, f: Fmt, function: Function) !void {
    try writer.print("{f} {{\n", .{f.proto(function)});

    try emitFunctionVarbs(writer, f, function.varbs);
    try emitFunctionBlock(writer, gpa, f, function.block);

    try writer.print("}}\n", .{});
}

fn emitFunctionVarbs(writer: *Writer, f: Fmt, varbs: LocationList) !void {
    const items = f.graph.locations[varbs.items..varbs.items+varbs.len];

    for (items) |item| {
        if (f.graph.emittable(item.typx))
            try writer.print("\t{f} {f};\n", .{f.typ(item), f.loc(item)});
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

                if (f.graph.emittable(location.typx))
                    try writer.print("\treturn {f};\n", .{f.loc(location)})
                else
                    try writer.print("\treturn;\n", .{});
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

            if (!f.graph.emittable(dst.typx)) return;

            try writer.print("\t{f} = {f};\n", .{
                f.loc(dst),
                f.con(src),
            });
        },
        .mov => |m| {
            const dst = f.graph.locations[m.dst];
            const src = f.graph.locations[m.src];

            if (!f.graph.emittable(dst.typx)) return;

            try writer.print("\t{f} = {f};\n", .{
                f.loc(dst),
                f.loc(src),
            });
        },
        .get => |m| {
            const dst = f.graph.locations[m.dst];
            const src = f.graph.locations[m.src];

            if (!f.graph.emittable(dst.typx)) return;

            try writer.print("\t{f} = *({f});\n", .{
                f.loc(dst),
                f.loc(src),
            });
        },
        .set => |m| {
            const dst = f.graph.locations[m.dst];
            const src = f.graph.locations[m.src];

            if (!f.graph.emittable(dst.typx)) return;

            try writer.print("\t*({f}) = {f};\n", .{
                f.loc(dst),
                f.loc(src),
            });
        },
        .ref => |m| {
            const dst = f.graph.locations[m.dst];
            const src = f.graph.locations[m.src];

            if (!f.graph.emittable(dst.typx)) return;

            try writer.print("\t{f} = &{f};\n", .{
                f.loc(dst),
                f.loc(src),
            });
        },
        .neg, .not => |m| {
            const dst = f.graph.locations[m.dst];
            const src = f.graph.locations[m.src];

            if (!f.graph.emittable(dst.typx)) return;

            const op = switch (inst) {
                .neg => "-",
                .not => "~",
                else => unreachable,
            };

            try writer.print("\t{f} = {s}{f};\n", .{
                f.loc(dst),
                op,
                f.loc(src),
            });
        },
        .add, .sub, .mul, .div, .mod, .ban, .ior, .xor, .shl, .shr, .eq, .ne, .lt, .gt, .le, .ge => |b| {
            const dst = f.graph.locations[b.dst];
            const lhs = f.graph.locations[b.lhs];
            const rhs = f.graph.locations[b.rhs];

            if (!f.graph.emittable(dst.typx)) return;

            const op = switch (inst) {
                .add => "+",
                .sub => "-",
                .mul => "*",
                .div => "/",
                .mod => "%",
                .ban => "&",
                .ior => "|",
                .xor => "^",
                .shl => "<<",
                .shr => ">>",
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

            try writer.print("\t", .{});

            if (f.graph.emittable(dst.typx))
                try writer.print("{f} = ", .{ f.loc(dst) });

            try writer.print("{f}(", .{f.loc(src)});

            for (args, 1..) |arg, idx| {
                try writer.print("{f}", .{f.loc(arg)});

                if (idx != args.len)
                    try writer.print(",", .{});
            }

            try writer.print(");\n", .{});
        },
    }
}
