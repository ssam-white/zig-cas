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
            pub const identity = 1;
            
            pub fn compute(a: T, b: T) T {
                return a * b;
            }

            pub const LinearCombinator = LinearCombination(T, struct {
                pub fn addToTerm(t: *linear_combination.Term(T), exp: Expression(T), factory: Factory(T)) !void {
                    const exp_as_pow = try exp.asPow(factory);
                    const exponent = exp_as_pow.Pow.exponent.*;
                    const new_value = try factory.add(&.{ t.value, exponent });
                    t.value = try new_value.simplify(factory);
                }

                pub fn isMatch(term: linear_combination.Term(T), exp: Expression(T)) bool {
                    if (exp != .Pow) return false;
                    return term.key.eqlStructure(exp.Pow.base.*);
                }

                pub fn termToExpression(term: linear_combination.Term(T), factory: Factory(T)) !Expression(T) {
                    return try Expression(T).pow(
                        try factory.create(term.key),
                        try factory.create(term.value)
                    ).simplify(factory);
                }

                pub fn termFromExpression(exp: Expression(T), factory: Factory(T)) !linear_combination.Term(T) {
                    const pow_exp = try exp.asPow(factory);
                    return .{
                        .key = pow_exp.Pow.base.*,
                        .value = pow_exp.Pow.exponent.*
                    };
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
                operands[i] = .mul(.fromOwnedSlice(factory.allocator, terms));
            }
            return .add(.fromOwnedSlice(factory.allocator, operands));
        }

        pub fn constantFold(self: Self, factory: Factory(T)) !Expression(T) {
            return .mul( try self.operands.constantFold(factory) );
        }

        pub fn expFromOperands(operands: MulOperands) Expression(T) {
            return switch (operands.list.items.len) {
                0 => .constant(1),
                1 => operands.list.items[0],
                else => .mul(operands)
            };
        }

        pub fn simplify(self: Self, factory: Factory(T)) !Expression(T) {
            const flattened = try self.operands.flatten(.Mul, factory);

            const filtered = try flattened.filter(factory);
            if (filtered.list.items.len < 2)
                return try expFromOperands(filtered).simplify(factory);

            const as_pow = try filtered.asPow(factory);
            const collected = try as_pow.collectLikeTerms(factory);
            const folded = try collected.constantFold(factory);

            const simplified = expFromOperands(folded);
            return if (simplified.isAnnihilated())
                .constant(0)
            else simplified;
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp != .Mul) return false;
            return self.operands.eqlStructure(exp.Mul.operands);
        }

        pub fn flatten(self: Self, factory: Factory(T)) !Expression(T) {
            const flat_operands = try self.operands.flatten(.Mul, factory);
            return .mul(flat_operands);
        }

        pub fn asPow(self: Self, factory: Factory(T)) !Expression(T) {
            const ops_as_pow = try self.operands.asPow(factory);
            return .mul( ops_as_pow );
        }


        pub const Factories = struct {
            pub fn mulPtr(factory: Factory(T), operands: []const Expression(T)) !*Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return try factory.mulPtr(operands_ptr);
            }

            pub fn mul(factory: Factory(T), operands: []const Expression(T)) !Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return .mul(.fromOwnedSlice(factory.allocator, operands_ptr));
            }
        };
    };
}
