const std = @import("std");
const Io = std.Io;

const lego = @import("lego");
const Block = lego.Block;
const Graph = lego.Graph;
const Allocation = lego.Allocation;

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    //const gpa = init.gpa;

    //const args = try init.minimal.args.toSlice(arena);
    //for (args) |arg| {
    //    std.log.info("arg: {s}", .{arg});
    //}

    const io = init.io;
    _ = io;

    var block0 = Block.init(arena);
    try block0.addInst(.{ .put = .{ .dst = "a", .src = 10 } });
    try block0.addInst(.{ .put = .{ .dst = "b", .src = 10 } });
    try block0.addInst(.{ .add = .{ .dst = "c", .lhs = "a", .rhs = "b" } });
    block0.setFlow(.{ .stop = "c" });

    var graph = Graph.init(arena);
    try graph.addBlock(block0);

    const allocation = try Allocation.scan(arena, graph);
    _ = allocation;
}
