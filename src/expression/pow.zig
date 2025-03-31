const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Pow(comptime T: type) type {
    return struct {
        base: *Expression(T),
        exponent: *Expression(T),

        const Self = @This();

        pub fn deinit(self: Self, alloc: std.mem.Allocator) void {
            self.base.*.deinit(alloc);
            alloc.destroy(self.base);
            self.exponent.*.deinit(alloc);
            alloc.destroy(self.exponent);
        }

        pub fn eval(self: Self, args: Expression(T).Args) T {
            return std.math.pow(T,
                self.base.*.eval(args),
                self.exponent.*.eval(args)
            );
        }

        pub fn print(self: Self) void {
            std.debug.print("( ", .{});
            self.base.print();
            std.debug.print(" ^ ", .{});
            self.exponent.print();
            std.debug.print(" )", .{});
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            switch (self.exponent.*) {
                .Const => |c| {
                    const operands = try factory.alloc.alloc(Expression(T), 2);

                    operands[0] = self.exponent.*;
                    operands[1] = .{ .Pow = .{
                        .base = self.base,
                        .exponent = try factory.constantAlloc(c.value - 1)
                    } };

                    return .{ .Mul = .{ .operands = operands } };
                },
                else => {
                    const operands = try factory.alloc.alloc(Expression(T), 2);
                    const expLogBaseProd = try factory.mulAlloc(&.{
                        self.exponent.*,
                        .{ .Log = .{
                            .b = try factory.constantAlloc(std.math.e),
                            .x = self.base
                        } }
                    });
                    defer expLogBaseProd.*.deinit(factory.alloc);

                    operands[0] = expLogBaseProd.*;
                    operands[1] = try expLogBaseProd.d(var_name, factory);

                    return .{ .Mul = .{ .operands = operands } };
                }
            }
        }
    };
}
