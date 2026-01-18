const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const StringList = std.StringArrayHashMap;

const Int = u32;
const Vdx = u32;

pub const Graph = struct {
    allocator: Allocator,
    functions: ArrayList(Function),
    locations: ArrayList(Location),
    blocks: ArrayList(Block),
    insts: ArrayList(Inst),
    typxs: ArrayList(Typx),
    //varbs: StringList(Int),
    extra: ArrayList(Int),

    pub fn deinit(self: *Graph) void {
        for (self.functions.items) |function|
            function.deinit();

        self.functions.deinit(self.allocator);
        self.locations.deinit(self.allocator);
        self.blocks.deinit(self.allocator);
        self.insts.deinit(self.allocator);
        self.typxs.deinit(self.allocator);
        self.extra.deinit(self.allocator);
    }
};

const Function = struct {
    name: []const u8,
    proto: Prototype,
    varbs: StringList(Int),
    block: Int,

    pub fn deinit(self: *Function) void {
        self.proto.deinit();
        self.varbs.deinit();
    }
};

const Prototype = struct {
    prms: StringList(Int),
    ret: Int,

    pub fn deinit(self: *Prototype) void {
        self.prms.deinit();
    }
};

const Block = struct {
    idx: Int,
    len: Int = 0, //NOTE, could be auto-incremented
    flow: Flow,

    const Flow = union(enum) {
        ret: Vdx,
        jmp: Vdx,
        jnz: struct { cond: Vdx, lhs: Int, rhs: Int },
    };
};

const Inst = union(enum) {
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

const Location = struct {
    code: Int,
    typx: Int,
};

const Typx = union(enum) {
    primitive: struct {
        bits: Int,
        sign: bool,
    },
    aggregate: struct {
        idx: Int,
        len: Int,
    },

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
