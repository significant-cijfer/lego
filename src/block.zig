const std = @import("std");
const Io = std.Io;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const lego = @import("root.zig");
const Int = lego.Int;
const Str = lego.Str;

pub const Block = struct {
    allocator: Allocator,
    insts: ArrayList(Inst),
    flow: Flow,

    pub fn init(gpa: Allocator) Block {
        return .{
            .allocator = gpa,
            .insts = .empty,
            .flow = undefined,
        };
    }

    pub fn addInst(self: *Block, inst: Inst) !void {
        try self.insts.append(self.allocator, inst);
    }

    pub fn setFlow(self: *Block, flow: Flow) void {
        self.flow = flow;
    }
};

const Inst = union(enum) {
    put: MonOp,
    add: BinOp,

    const MonOp = struct {
        dst: Str,
        src: Int,
    };

    const BinOp = struct {
        dst: Str,
        lhs: Str,
        rhs: Str,
    };
};

const Flow = union(enum) {
    jump: Int,
    stop: Str,
    split: Cond,

    const Cond = struct {
        check: Str,
        success: Int,
        failure: Int,
    };
};
