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

    const exp = try f.logPtr(
        try f.constantPtr(std.math.e),
        try f.powPtr(
            try f.variablePtr("x"),
            try f.constantPtr(2)
        )
    );
    
    const value = try exp.*.d("x", f);
    std.debug.print("d/dx(", .{});
    exp.*.print();
    std.debug.print(") = ", .{});
    value.print();

    std.debug.print("\n", .{});
    // std.debug.print("{d}\n", .{ (try exp.*.d("x", f)).eval(&.{ .{ "x", F.constant(3) } })});
}

