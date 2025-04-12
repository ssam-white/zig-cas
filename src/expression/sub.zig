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
            pub const identity = 0;

            pub fn compute(a: T, b: T) T {
                return a - b;
            }

            pub const LinearCombinator = LinearCombination(T, struct {
                pub fn addToTerm(t: *linear_combination.Term(T), _: Expression(T), factory: Factory(T)) !void {
                    t.value = try factory.sub(&.{ t.value, .constant(1) });
                }

                pub fn isMatch(term: linear_combination.Term(T), exp: Expression(T)) bool {
                    return term.key.eqlStructure(exp);
                }

                pub fn termToExpression(term: linear_combination.Term(T), factory: Factory(T)) !Expression(T) {
                    return try factory.mul(&.{ term.value, term.key });
                }

                pub fn termFromExpression(exp: Expression(T), _: Factory(T)) !linear_combination.Term(T) {
                    return .{
                        .key = exp,
                        .value = .constant(1)
                    };
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

        pub fn constantFold(self: Self, factory: Factory(T)) !Expression(T) {
            return .sub( try self.operands.constantFold(factory) );
        }

        pub fn expFromOperands(operands: SubOperands) Expression(T) {
            return switch (operands.list.items.len) {
                0 => .constant(0),
                1 => operands.list.items[0],
                else => .sub(operands)
            };
        }

        pub fn simplify(self: Self, factory: Factory(T)) !Expression(T) {
            const filtered = try self.operands.filter(factory);
            const collected = try filtered.collectLikeTerms(factory);
            return expFromOperands(collected);
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
                return .sub(.fromOwnedSlice(factory.allocator, operands_ptr));
            }
        };
    };
}
