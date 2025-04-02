const std = @import("std");
const Ast = @import("ast.zig").Ast;
const Expression = @import("expression.zig").Expression;
const Factory = @import("factory.zig").Factory;
const Add = @import("expression/add.zig").Add;

const E = Expression(f32);

const F = Factory(f32);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const f = try F.init(alloc);
    defer f.deinit();

    const a = try f.sub(&.{
        F.variable("x"),
        F.variable("x")
    });

    const b = try f.add(&.{
        F.variable("x"),
        F.variable("x")
    });

    (try a.rewrite(f)).print();
    std.debug.print("\n", .{});
    (try b.rewrite(f)).print();
    
    std.debug.print("\n", .{});
}

