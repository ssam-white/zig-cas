const std = @import("std");
const Ast = @import("ast.zig").Ast;
const Expression = @import("expression.zig").Expression;
const Factory = @import("factory.zig").Factory;
const Add = @import("expression/add.zig").Add;

const E = Expression(f32);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const f: Factory(f32) = try .init(alloc);
    defer f.deinit();

    const b = try f.mul(&.{
        .variable("x"),
        .variable("x"),
        .variable("x"),
    });

    const br = try b.rewrite(f);
    b.print();
    std.debug.print(" = ", .{});
    br.print();
    
    
    std.debug.print("\n", .{});
}

