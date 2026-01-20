const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Int = u32;
pub const Vdx = u32;

pub const Graph = struct {
    allocator: Allocator,
    functions: ArrayList(Function),
    locations: ArrayList(Location),
    strings: ArrayList([]const u8),
    blocks: ArrayList(Block),
    insts: ArrayList(Inst),
    typxs: ArrayList(Typx),
    extra: ArrayList(Int),
    text: [:0]const u8,

    pub fn deinit(self: *Graph) void {
        for (self.functions.items) |function|
            function.deinit();

        self.functions.deinit(self.allocator);
        self.locations.deinit(self.allocator);
        self.strings.deinit(self.allocator);
        self.blocks.deinit(self.allocator);
        self.insts.deinit(self.allocator);
        self.typxs.deinit(self.allocator);
        self.extra.deinit(self.allocator);
    }
};

pub const Function = struct {
    name: []const u8,
    proto: Prototype,
    varbs: StringList,
    block: Int,

    pub fn deinit(self: *Function) void {
        self.proto.deinit();
        self.varbs.deinit();
    }

    pub fn fmtProto(self: Function, graph: Graph, comptime Fmt: anytype) Fmt.Prototype {
        return .{
            .graph = graph,
            .cell = self,
        };
    }
};

const Prototype = struct {
    prms: StringList,
    ret: Int,

    pub fn deinit(self: *Prototype) void {
        self.prms.deinit();
    }
};

pub const StringList = struct {
    names: Int,
    items: Int,
    len: Int,
};

pub const Block = struct {
    idx: Int,
    len: Int = 0, //NOTE, could be auto-incremented
    flow: Flow,

    const Flow = union(enum) {
        ret: Vdx,
        jmp: Vdx,
        jnz: struct { cond: Vdx, lhs: Int, rhs: Int },
    };
};

pub const Inst = union(enum) {
    put: MonOp, //constant
    get: MonOp, //mem
    set: MonOp, //mem
    add: BinOp,
    sub: BinOp,
    mul: BinOp,
    div: BinOp,
    call: VarOp,

    const MonOp = struct {
        dst: Vdx,
        src: Vdx,
    };

    const BinOp = struct {
        dst: Vdx,
        lhs: Vdx,
        rhs: Vdx,
    };

    const VarOp = struct {
        dst: Vdx,
        idx: Int,
        len: Int,
    };
};

pub const Location = struct {
    code: Int,
    typx: Int,
};

pub const Typx = union(enum) {
    primitive: struct {
        bits: Int,
        sign: bool,
    },
    aggregate: StringList,

    pub fn fmt(self: Typx, graph: Graph, comptime Fmt: anytype) Fmt.Type {
        return .{
            .graph = graph,
            .cell = self,
        };
    }

    //pub fn format(self: Typx, writer: *std.Io.Writer) !void {
    //    switch (self) {
    //        .primitive => |p| {
    //            const bits = p.bits;
    //            const sign = if (p.sign) 'i' else 'u';

    //            try writer.print("{c}{d}", .{sign, bits});
    //        },
    //    }
    //}
};
