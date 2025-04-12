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

    const b: E = try f.mul(&.{
        try f.mul(&.{
            .constant(3),
            .constant(3),
        }),
        try f.mul(&.{
            .constant(3),
            .constant(3),
        }),
        try f.mul(&.{
            .constant(2),
            .constant(2),
        }),
        try f.mul(&.{
            .constant(2),
            .constant(2),
        }),
    });

    b.print();
    std.debug.print("\n= ", .{});
    const br = try b.simplify(f);
    br.print();
    std.debug.print("\n", .{});
}
