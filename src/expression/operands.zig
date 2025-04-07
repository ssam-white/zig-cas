const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;
const LinearCombination = @import("../linearCombination.zig").LinearCombination;

pub fn Operands(
    comptime T: type,
    comptime Context: type
) type {
    return struct {
        items: []Expression(T),

        const Self = @This();
        
        pub fn init(items: []Expression(T)) Self {
            return .{ .items = items };
        }

        pub fn filter(self: Self, factory: Factory(T)) !Self {
            const operands = try factory.alloc(self.items.len);
            var num_ops: usize = 0;
            for (self.items) |exp| {
                const simple_exp = try exp.rewrite(factory);
                if (Context.filters(simple_exp)) continue;
                operands[num_ops] = simple_exp;
                num_ops += 1;
            }
            return .init(operands[0..num_ops]);
        }

        pub fn print(self: Self, operator: []const u8) void {
            std.debug.print("( ", .{});
            defer std.debug.print(" )", .{});
            
            if (self.items.len == 0) return;
            self.items[0].print();

            for (self.items[1..]) |e| {
                std.debug.print(" {s} ", .{ operator });
                e.print();
            }
        }

        pub fn deriveTerms(self: Self, var_name: []const u8, factory: Factory(T)) !Self {
            const d_ops = try factory.alloc(self.items.len);
            for (self.items, 0..) |exp, i| {
                d_ops[i] = try exp.d(var_name, factory);
            }
            return .init(d_ops);
        }

        pub fn collectLikeTerms(self: Self, factory: Factory(T)) !Self {
            var like_terms = Context.LinearCombinator.init(factory.allocator);
            defer like_terms.deinit();
            const collected = try like_terms.collect(self.items, factory);
            return .init(collected);
        }
    };
}
