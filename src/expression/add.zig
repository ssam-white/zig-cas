const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;
const linear_combination = @import("../linearCombination.zig");

fn AddLikeTerms(comptime T: type) type {
    const Context = struct {
        pub fn addToTerm(self: *linear_combination.Term(T)) void {
            self.value += 1;
        }
    };
    return linear_combination.LinearCombination(T, Context);
}

pub fn Add(comptime T: type) type {
    return struct {
        operands: []const Expression(T),

        const Self = @This();
        
        pub fn eval(self: Self, args: Expression(T).Args) T {
            var sum = self.operands[0].eval(args);
            for (self.operands[1..]) |e| {
                sum += e.eval(args);
            }
            return sum;
        }

        pub fn print(self: Self) void {
            std.debug.print("( ", .{});
            defer std.debug.print(" )", .{});
            
            if (self.operands.len == 0) return;
            self.operands[0].print();

            for (self.operands[1..]) |e| {
                std.debug.print(" + ", .{});
                e.print();
            }
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            const dops = try factory.alloc(self.operands.len);
            for (self.operands, 0..) |exp, i| {
                dops[i] = try exp.d(var_name, factory);
            }
            return .{ .Add = .{ .operands = dops } };
        }

        fn rewriteFilter(exp: Expression(T)) bool {
            !(return exp == .Const and exp.Const.value == 0);
        }
        
        pub fn rewrite(self: Self, factory: Factory(T)) !Expression(T) {
            const operands = try factory.alloc(self.operands.len);
            defer factory.allocator.free(operands);
            
            var num_ops: usize = 0;
            for (self.operands) |exp| {
                const simple_exp = try exp.rewrite(factory);
                if (rewriteFilter(simple_exp)) continue;

                operands[num_ops] = simple_exp;
                num_ops += 1;
            }

            var like_terms = AddLikeTerms(T).init(factory.allocator);
            defer like_terms.deinit();
            
            const collected_ops = try like_terms.collect(operands, factory);

            return switch (collected_ops.len) {
                0 => Factory(T).constant(0),
                1 => collected_ops[0],
                else => try factory.add(collected_ops)
            };
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp == .Add) return false;
            return Expression(T).allEqlStructure(self.operands, exp.Add.operands);
        }

        pub const Factories = struct {
            pub fn addPtr(factory: Factory(T), operands: []const Expression(T)) !*Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return try factory.create(.{ .Add = .{ .operands = operands_ptr } });
            }

            pub fn add(factory: Factory(T), operands: []const Expression(T)) !Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return .{ .Add = .{ .operands = operands_ptr } };
            }
        };
    };
}
