const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;
const Operands = @import("operands.zig").Operands;
const linear_combination = @import("../linear-combination.zig");
const LinearCombination = linear_combination.LinearCombination;

pub fn Mul(comptime T: type) type {
    return struct {
        operands: MulOperands,

        const Self = @This();

        const MulOperands = Operands(T, struct {
            pub fn filters(exp: Expression(T)) bool {
                _ = exp;
                return false;//exp.eqlStructure(.constant(1));
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
            const operands = try factory.alloc(self.operands.list.items.len);
            for (operands, 0..) |_, i| {
                const terms = try factory.allocAll(self.operands.list.items);
                terms[i] = try self.operands.list.items[i].d(var_name, factory);
                operands[i] = .mul(.init(factory.allocator, terms));
            }
            return .add(.init(factory.allocator, operands));
        }

        pub fn rewrite(self: Self, factory: Factory(T)) !Expression(T) {
            const filtered = try self.operands.filter(factory);
            const collected_ops = try filtered.collectLikeTerms(factory);

            return switch (collected_ops.list.items.len) {
                0 => .constant(0),
                1 => collected_ops.list.items[0],
                else => try factory.mul(collected_ops.list.items)
            };
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp != .Mul) return false;
            return self.operands.eqlStructure(exp.Mul.operands);
        }

        pub fn flatten(self: Self, factory: Factory(T)) !Expression(T) {
            const flat_operands = try self.operands.flatten(.Mul, factory);
            return .mul(flat_operands);
        }

        pub const Factories = struct {
            pub fn mulPtr(factory: Factory(T), operands: []const Expression(T)) !*Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return try factory.mulPtr(operands_ptr);
            }

            pub fn mul(factory: Factory(T), operands: []const Expression(T)) !Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return .mul(.init(factory.allocator, operands_ptr));
            }
        };
    };
}
