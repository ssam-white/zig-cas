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
            pub const identity = 0;

            pub fn compute(a: T, b: T) T {
                return a + b;
            }

            pub const LinearCombinator = LinearCombination(T, struct {
                pub fn addToTerm(term: *linear_combination.Term(T), _: Expression(T), factory: Factory(T)) !void {
                    const new_value = try factory.add(&.{ term.value, .constant(1) });
                    term.value = try new_value.rewrite(factory);
                }

                pub fn isMatch(term: linear_combination.Term(T), exp: Expression(T)) bool {
                    return term.key.eqlStructure(exp);
                }

                pub fn termToExpression(term: linear_combination.Term(T), factory: Factory(T)) !Expression(T) {
                    const prod = try factory.mul(&.{ term.value, term.key });
                    return prod.rewrite(factory);
                }

                pub fn termFromExpression(exp: Expression(T), _: Factory(T)) !linear_combination.Term(T) {
                    return .{
                        .key = exp,
                        .value = .constant(1)
                    };
                }
            });
        });

        pub fn initExp(operands: AddOperands) Expression(T) {
            return .{ .Add = .{ .operands = operands } };
        }
        
        pub fn eval(self: Self, args: Expression(T).Args) T {
            var sum = self.operands.list[0].eval(args);
            for (self.operands.list[1..]) |e| {
                sum += e.eval(args);
            }
            return sum;
        }

        pub fn print(self: Self) void {
            self.operands.print("+");
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            const d_ops = try self.operands.deriveTerms(var_name, factory);
            return .add(d_ops);
        }


        pub fn constantFold(self: Self, factory: Factory(T)) !Expression(T) {
            return .add( try self.operands.constantFold(factory) );
        }

        pub fn expFromOperands(operands: AddOperands) Expression(T) {
            return switch (operands.list.items.len) {
                0 => .constant(0),
                1 => operands.list.items[0],
                else => .add(operands)
            };
        }

        pub fn simplify(self: Self, factory: Factory(T)) !Expression(T) {
            const flattened = try self.operands.flatten(.Add, factory);
            const filtered = try flattened.filter(factory);
            const folded = try filtered.constantFold(factory);
            const collected = try folded.collectLikeTerms(factory);
            
            return expFromOperands(collected);
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp != .Add) return false;
            return self.operands.eqlStructure(exp.Add.operands);
        }

        pub fn flatten(self: Self, factory: Factory(T)) !Expression(T) {
            const flat_operands = try self.operands.flatten(.Add, factory);
            return .add(flat_operands);
        }

        pub const Factories = struct {
            pub fn addPtr(factory: Factory(T), operands: []const Expression(T)) !*Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return try factory.create(.add(factory.allocator, operands_ptr));
            }

            pub fn add(factory: Factory(T), operands: []const Expression(T)) !Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return .add(.fromOwnedSlice(factory.allocator, operands_ptr));
            }
        };
    };
}
