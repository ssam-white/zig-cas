const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;
const linear_combination = @import("../linearCombination.zig");

pub fn Sub(comptime T: type) type {
    return struct {
        operands: []const Expression(T),

        const Self = @This();

        pub fn initExp(operands: []const Expression(T)) Expression(T) {
            return .{ .Sub = .{ .operands = operands } };
        }
        
        pub fn eval(self: Self, args: Expression(T).Args) T {
            var sum = self.operands[0].eval(args);
            for (self.operands[1..]) |e| {
                sum -= e.eval(args);
            }
            return sum;
        }

        pub fn print(self: Self) void {
            std.debug.print("( ", .{});
            defer std.debug.print(" )", .{});

            if (self.operands.len == 0) return;
            self.operands[0].print();

            for (self.operands[1..]) |e| {
                std.debug.print(" - ", .{});
                e.print();
            }
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            const operands = try factory.alloc(self.operands.len);
            for (self.operands, 0..) |e, i| {
                operands[i] = try e.d(var_name, factory);
            }
            return .sub(operands);
        }


        const SubLikeTerms = linear_combination.LinearCombination(T, struct {
            pub fn addToTerm(self: *linear_combination.Term(T)) void {
                self.value -= 1;
            }
        });

        pub fn rewrite(self: Self, factory: Factory(T)) !Expression(T) {
            const operands = try factory.alloc(self.operands.len);
            var num_ops: usize = 0;
            for (self.operands) |exp| {
                const simple_exp = try exp.rewrite(factory);

                if (simple_exp.eqlStructure(.constant(0))) continue;

                operands[num_ops] = simple_exp;
                num_ops += 1;
            }

            var like_terms = SubLikeTerms.init(factory.allocator);
            defer like_terms.deinit();
            const collected_ops = try like_terms.collect(operands, factory);
            
            return switch (collected_ops.len) {
                0 => .constant(0),
                1 => collected_ops[0],
                else => try factory.sub(collected_ops)
            };
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp == .Sub) return false;
            return Expression(T).allEqlStructure(self.operands, exp.Add.operands.items);
        }

        pub const Factories = struct {
            pub fn subPtr(factory: Factory(T), operands: []const Expression(T)) !*Expression(T) {
                return try factory.create(try factory.sub(operands));
            }

            pub fn sub(factory: Factory(T), operands: []const Expression(T)) !Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return .sub(operands_ptr);
            }
        };
    };
}
