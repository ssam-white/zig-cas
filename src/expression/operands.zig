const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;
const LinearCombination = @import("../linear-combination.zig").LinearCombination;

const ArrayList = std.ArrayList;

pub fn Operands(
    comptime T: type,
    comptime Context: type
) type {
    return struct {
        list: ArrayList(Expression(T)),

        const Self = @This();
        
        pub fn init(allocator: std.mem.Allocator, items: []Expression(T)) Self {
            const list = ArrayList(Expression(T)).fromOwnedSlice(allocator, items);
            return .{ .list = list };
        }

        pub fn append(self: *Self, exp: Expression(T)) !void {
            try self.list.append(exp);
        }

        pub fn filter(self: Self, factory: Factory(T)) !Self {
            const operands = try factory.alloc(self.list.items.len);
            var num_ops: usize = 0;
            for (self.list.items) |exp| {
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
            
            if (self.list.items.len == 0) return;
            self.list.items[0].print();

            for (self.list.items[1..]) |e| {
                std.debug.print(" {s} ", .{ operator });
                e.print();
            }
        }

        pub fn deriveTerms(self: Self, var_name: []const u8, factory: Factory(T)) !Self {
            const d_ops = try factory.alloc(self.list.items.len);
            for (self.list.items, 0..) |exp, i| {
                d_ops[i] = try exp.d(var_name, factory);
            }
            return .init(factory.allocator, d_ops);
        }

        pub fn collectLikeTerms(self: Self, factory: Factory(T)) !Self {
            var like_terms = Context.LinearCombinator.init(factory.allocator);
            defer like_terms.deinit();
            const collected = try like_terms.collect(self.list.items, factory);
            return .init(collected);
        }

        pub fn eqlStructure(self: Self, other: Self) bool {
            if (self.list.items.len != other.list.items.len) return false;
            for (self.list.items, other.list.items) |s, o| {
                if (!s.eqlStructure(o)) return false;
            } 
            return true;
        }

        pub fn flatten(
            self: Self,
            comptime tag: Expression(T).Tag,
            factory: Factory(T)
        ) !Self {
            var new_operands = Self.init(factory.allocator, &.{});
            for (self.list.items) |exp| {
                if (exp == tag) {
                    const to_flatten = @field(exp, @tagName(tag));
                    for (to_flatten.operands.list.items) |to_add| {
                        try new_operands.append(to_add);
                    }
                } else {
                    try new_operands.append(exp);
                }
            }
            return new_operands;
        }
    };
}
