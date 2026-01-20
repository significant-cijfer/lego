const std = @import("std");
const lib = @import("lego");

const stderr = std.fs.File.stderr();

const Graph = lib.Graph;

pub fn main() !void {
//}
//
//// This test only exists to force the compiler to fully check all files
//test "Empty Graph (x86-64 linux)" {
    const target = @import("target/C_linux.zig");

    //const gpa = std.testing.allocator;
    var dba = std.heap.DebugAllocator(.{}){};
    const gpa = dba.allocator();

    const graph = Graph{
        .allocator = gpa,
        .functions = .empty,
        .locations = .empty,
        .strings = .empty,
        .blocks = .empty,
        .insts = .empty,
        .typxs = .empty,
        .extra = .empty,
        .text = "",
    };

    var buffer: [8192]u8 = undefined;
    var writer = stderr.writer(&buffer);

    try target.emit(&writer.interface, graph);
}
