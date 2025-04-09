const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;
const linear_combination = @import("../linear-combination.zig");
const LinearCombination = linear_combination.LinearCombination;
const Operands = @import("operands.zig").Operands;

pub fn Add(comptime T: type) type {
    return struct {
        operands: AddOperands,

        const Self = @This();

        const AddOperands = Operands(T, struct {
            pub fn filters(exp: Expression(T)) bool {
                return exp.eqlStructure(.constant(0));
            }

            pub const LinearCombinator = LinearCombination(T, struct {
                pub fn addToTerm(s: *linear_combination.Term(T)) void {
                    s.value += 1;
                }

                pub fn termToExpression(term: linear_combination.Term(T), factory: Factory(T)) !Expression(T) {
                    return try factory.mul(&.{
                        .constant(term.value),
                        term.key
                    });
                }
            });
        });

        pub fn initExp(operands: AddOperands) Expression(T) {
            return .{ .Add = .{ .operands = operands } };
        }
        
        pub fn eval(self: Self, args: Expression(T).Args) T {
            var sum = self.operands.items[0].eval(args);
            for (self.operands.items[1..]) |e| {
                sum += e.eval(args);
            }
            return sum;
        }

        pub fn print(self: Self) void {
            self.operands.print("+");
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            const d_ops = try self.operands.deriveTerms(var_name, factory);
            return .add(.init(d_ops.items));
        }

        pub fn rewrite(self: Self, factory: Factory(T)) !Expression(T) {
            const filtered = try self.operands.filter(factory);
            const collected_ops = try filtered.collectLikeTerms(factory);
            
            return switch (collected_ops.items.len) {
                0 => .constant(0),
                1 => collected_ops.items[0],
                else => try factory.add(collected_ops.items)
            };
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp != .Add) return false;
            return Expression(T).allEqlStructure(self.operands.items, exp.Add.operands.items);
        }

        pub const Factories = struct {
            pub fn addPtr(factory: Factory(T), operands: []const Expression(T)) !*Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return try factory.create(add(operands_ptr));
            }

            pub fn add(factory: Factory(T), operands: []const Expression(T)) !Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return .add(.init(operands_ptr));
            }
        };
    };
}
