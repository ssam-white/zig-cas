const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;
const linear_combination = @import("../linear-combination.zig");
const Operands = @import("operands.zig").Operands;
const LinearCombination = @import("../linear-combination.zig").LinearCombination;

pub fn Sub(comptime T: type) type {
    return struct {
        operands: SubOperands,

        const Self = @This();

        const SubOperands = Operands(T, struct {
            pub fn filters(exp: Expression(T)) bool {
                return exp.eqlStructure(.constant(0));
            }

            pub const LinearCombinator = LinearCombination(T, struct {
                pub fn addToTerm(s: *linear_combination.Term(T)) void {
                    s.value -= 1;
                }

                pub fn termToExpression(term: linear_combination.Term(T), factory: Factory(T)) !Expression(T) {
                    return try factory.mul(&.{
                        .constant(term.value),
                        term.key
                    });
                }
            });

        });

        pub fn initExp(operands: SubOperands) Expression(T) {
            return .{ .Sub = .{ .operands = operands } };
        }
        
        pub fn eval(self: Self, args: Expression(T).Args) T {
            var sum = self.operands.list[0].eval(args);
            for (self.operands.list[1..]) |e| {
                sum -= e.eval(args);
            }
            return sum;
        }

        pub fn print(self: Self) void {
            self.operands.print("-");
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            const d_ops = try self.operands.deriveTerms(var_name, factory);
            return .sub(d_ops);
        }

        pub fn rewrite(self: Self, factory: Factory(T)) !Expression(T) {
            const filtered = try self.operands.filter(factory);
            const collected_ops = try filtered.collectLikeTerms(factory);

            return switch (collected_ops.list.len) {
                0 => .constant(0),
                1 => collected_ops.list[0],
                else => try factory.sub(collected_ops.list)
            };
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp == .Sub) return false;
            return self.operands.eqlStructure(exp.Sub.operands);
        }

        pub fn flatten(self: Self, factory: Factory(T)) !Expression(T) {
            const flat_operands = try self.operands.flatten(.Sub, factory);
            return .sub(flat_operands);
        }

        pub const Factories = struct {
            pub fn subPtr(factory: Factory(T), operands: []const Expression(T)) !*Expression(T) {
                return try factory.create(try factory.sub(operands));
            }

            pub fn sub(factory: Factory(T), operands: []const Expression(T)) !Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return .sub(.init(factory.allocator, operands_ptr));
            }
        };
    };
}
