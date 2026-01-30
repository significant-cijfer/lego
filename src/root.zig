const std = @import("std");

pub const backend = @import("backend.zig");

pub const Int = u32;
pub const Vdx = u32;
pub const BigInt = std.math.big.int.Const;

pub const Graph = struct {
    functions: []const Function,
    locations: []const Location,
    constants: []const Constant,
    strings: []const []const u8,
    blocks: []const Block,
    insts: []const Inst,
    typxs: []const Typx,
    root: Root,
};

pub const Root = struct {
    varbs: StringExtraList,
};

pub const Function = struct {
    ident: Int,
    proto: Prototype,
    varbs: StringList,
    block: Int,
};

pub const Prototype = struct {
    prms: StringList,
    ret: Int,
};

pub const StringList = struct {
    names: Int,
    items: Int,
    len: Int,
};

pub const StringExtraList = struct {
    names: Int,
    items: Int,
    extra: Int,
    len: Int,
};

pub const Block = struct {
    idx: Int,
    len: Int,
    flow: Flow,

    pub const Flow = union(enum) {
        ret: Int,
        jmp: Int,
        jnz: struct { cond: Vdx, lhs: Int, rhs: Int },
    };
};

pub const Inst = union(enum) {
    put: ConOp,
    mov: MonOp,
    get: MonOp,
    set: MonOp,
    neg: MonOp,
    not: MonOp,
    add: BinOp,
    sub: BinOp,
    mul: BinOp,
    div: BinOp,
    mod: BinOp,
    ban: BinOp,
    ior: BinOp,
    xor: BinOp,
    shl: BinOp,
    shr: BinOp,
    eq: BinOp,
    ne: BinOp,
    lt: BinOp,
    gt: BinOp,
    le: BinOp,
    ge: BinOp,
    call: VarOp,

    const ConOp = struct {
        dst: Vdx,
        src: Int,
    };

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
        src: Vdx,
        idx: Int,
        len: Int,
    };
};

pub const Location = struct {
    code: Code,
    typx: Int,

    //TODO, figure out if `temp` should be placed above or below
    const Code = packed struct {
        temp: bool,
        token: std.meta.Int(.unsigned, @typeInfo(Int).int.bits-1),
    };
};

pub const Constant = union(enum) {
    primitive: BigInt,
    aggregate: StringList,
};

pub const Typx = union(enum) {
    primitive: struct {
        bits: Int,
        sign: bool,
    },
    aggregate: StringList,

    //NOTE, size in bytes - bitpadding
    pub fn size(self: Typx, graph: *const Graph) Int {
        return switch (self) {
            .primitive => |p| std.math.divCeil(Int, p.bits, 8) catch unreachable, //NOTE, if this ever fucking fails, ill eat pineapple on a pizza
            .aggregate => |a| b: {
                const typxs = graph.typxs[a.items..a.items+a.len];
                var sz: Int = 0;

                for (typxs) |typx|
                    sz += typx.size(graph);

                break :b sz;
            },
        };
    }
};
