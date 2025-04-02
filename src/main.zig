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

    const exp = try f.addPtr(&.{
        F.variable("x"),
        F.variable("x"),
        F.variable("x"),
        F.variable("y"),
        F.variable("y"),
        F.variable("z")
    });


   
    const r = try exp.*.rewrite(f);
    r.print();
    
    std.debug.print("\n", .{});
}

