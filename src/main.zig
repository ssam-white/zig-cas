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

    const f = F.init(alloc);

    const ast = Ast(f32).init(
        f.alloc,
        try f.powAlloc(
            try f.variableAlloc("x"),
            try f.constantAlloc(2)
        )
    );
    defer ast.deinit();
    
    const value = try ast.exp.*.d("x", f);
    // defer value.Mul.operands[1].Pow.exponent.*.deinit(f.alloc);
    // defer f.alloc.destroy(value.Mul.operands[1].Pow.exponent);
    // defer f.alloc.free(value.Mul.operands);
    
    value.print();

    std.debug.print("\n", .{});
}

