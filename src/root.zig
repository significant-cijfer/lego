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

    pub fn emittable(self: Graph, typx: Int) bool {
        return switch (self.typxs[typx]) {
            .noval => false,
            else => true,
        };
    }
};

pub const Root = struct {
    imports: StringList,
    externs: LocationList,
    varbs: LocationExtraList,
};

pub const Function = struct {
    ident: Int,
    proto: Prototype,
    varbs: LocationList,
    block: Int,
};

pub const Prototype = struct {
    prms: LocationList,
    ret: Int,
};

pub const LocationList = struct {
    items: Int,
    len: Int,
};

pub const LocationExtraList = struct {
    items: Int,
    extra: Int,
    len: Int,
};

pub const StringList = struct {
    names: Int,
    items: Int,
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
    ref: MonOp,
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

    pub const ConOp = struct {
        dst: Vdx,
        src: Int,
    };

    pub const MonOp = struct {
        dst: Vdx,
        src: Vdx,
    };

    pub const BinOp = struct {
        dst: Vdx,
        lhs: Vdx,
        rhs: Vdx,
    };

    pub const VarOp = struct {
        dst: Vdx,
        src: Vdx,
        idx: Int,
        len: Int,
    };
};

pub const Location = struct {
    code: Code,
    typx: Int,

    const Code = struct {
        token: Int,
        temp: bool,
    };
};

pub const Constant = union(enum) {
    primitive: BigInt,
    aggregate: StringList,
};

pub const Typx = union(enum) {
    noval: void,
    word: void,
    pointer: Int,
    function: Callable,
    primitive: Primitive,
    aggregate: StringList,

    const Primitive = struct {
        bits: Int,
        sign: bool,
    };

    const Callable = struct {
        prms: Int,
        len: Int,
        ret: Int,
    };

    //NOTE, size in bytes - bitpadding
    pub fn size(self: Typx, graph: *const Graph) Int {
        return switch (self) {
            .word,
            .pointer => 8, //TODO, this should be platform specific, im assuming 8bytes for now (amd64)
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
