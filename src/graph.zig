const std = @import("std");
const Io = std.Io;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const lego = @import("root.zig");
const Block = lego.Block;

pub const Graph = struct {
    allocator: Allocator,
    blocks: ArrayList(Block),

    pub fn init(gpa: Allocator) Graph {
        return .{
            .allocator = gpa,
            .blocks = .empty,
        };
    }

    pub fn addBlock(self: *Graph, block: Block) !void {
        try self.blocks.append(self.allocator, block);
    }
};
