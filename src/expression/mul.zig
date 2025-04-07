const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;
const Operands = @import("operands.zig").Operands;
const linear_combination = @import("../linearCombination.zig");
const LinearCombination = linear_combination.LinearCombination;

pub fn Mul(comptime T: type) type {
    return struct {
        operands: MulOperands,

        const Self = @This();

        const MulOperands = Operands(T, struct {
            pub fn filters(exp: Expression(T)) bool {
                return exp.eqlStructure(.constant(1));
            }

            pub const LinearCombinator = LinearCombination(T, struct {
                pub fn addToTerm(s: *linear_combination.Term(T)) void {
                    s.value += 1;
                }

                pub fn termToExpression(term: linear_combination.Term(T), factory: Factory(T)) !Expression(T) {
                    return .pow(
                        try factory.create(term.key),
                        try factory.constantPtr(term.value)
                    );
                }

            });
        });

        pub fn initExp(operands: MulOperands) Expression(T) {
            return .{ .Mul = .{ .operands = operands } };
        }

        pub fn eval(self: Self, args: Expression(T).Args) T {
            var prod = self.operands[0].eval(args);
            for (self.operands[1..]) |e| {
                prod *= e.eval(args);
            }
            return prod;
        }

        pub fn print(self: Self) void {
            self.operands.print("*");
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            const d_ops = try self.operands.deriveTerms(var_name, factory);
            return .mul(d_ops);
        }

        pub fn rewrite(self: Self, factory: Factory(T)) !Expression(T) {
            const filtered = try self.operands.filter(factory);
            const collected_ops = try filtered.collectLikeTerms(factory);

            return switch (collected_ops.items.len) {
                0 => .constant(0),
                1 => collected_ops.items[0],
                else => try factory.mul(collected_ops.items)
            };
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp == .Mul) return false;
            return Expression(T).allEqlStructure(self.operands.items, exp.Mul.operands.items);
        }

        pub const Factories = struct {
            pub fn mulPtr(factory: Factory(T), operands: []const Expression(T)) !*Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return try factory.mulPtr(operands_ptr);
            }

            pub fn mul(factory: Factory(T), operands: []const Expression(T)) !Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return .mul(.init(operands_ptr));
            }
        };
    };
}
