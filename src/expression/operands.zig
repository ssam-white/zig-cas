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
        const Errors = error {
            AsPowError,
        };

        list: ArrayList(Expression(T)),

        const Self = @This();
        
        pub fn init(allocator: std.mem.Allocator) Self {
            const list = std.ArrayList(Expression(T)).init(allocator);
            return .{ .list = list };
        }

        pub fn fromOwnedSlice(allocator: std.mem.Allocator, items: []Expression(T)) Self {
            const list = ArrayList(Expression(T)).fromOwnedSlice(allocator, items);
            return .{ .list = list };
        }

        pub fn append(self: *Self, exp: Expression(T)) !void {
            try self.list.append(exp);
        }

        pub fn filter(self: Self, factory: Factory(T)) !Self {
            var new_operands = Self.init(factory.allocator);
            for (self.list.items) |exp| {
                const simple_exp = try exp.simplify(factory);
                if (simple_exp.eqlStructure(
                    .constant(Context.identity)
                )) {
                    continue;
                }
                try new_operands.append(simple_exp);
            }
            return new_operands;
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
            return .fromOwnedSlice(factory.allocator, d_ops);
        }

        pub fn collectLikeTerms(self: Self, factory: Factory(T)) !Self {
            if (self.list.items.len == 1) return self;
            
            var like_terms = Context.LinearCombinator.init(factory.allocator);
            const collected = try like_terms.collect(self.list.items, factory);
            return .fromOwnedSlice(factory.allocator, collected);
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
            var new_operands = Self.init(factory.allocator);
            for (self.list.items) |exp| {
                if (exp == tag) {
                    const flat_exp = try exp.flatten(factory);
                    const to_flatten = @field(flat_exp, @tagName(tag));
                    for (to_flatten.operands.list.items) |to_add| {
                        try new_operands.append(to_add);
                    }
                } else {
                    try new_operands.append(exp);
                }
            }
            return new_operands;
        }

        pub fn asPow(self: Self, factory: Factory(T)) anyerror!Self {
            var new_operands = Self.init(factory.allocator);
            for (self.list.items) |exp| {
                try new_operands.append(try exp.asPow(factory));
            }
            return new_operands;
        }

        pub fn flattenAndFold(
            self: Self,
            comptime tag: Expression(T).Tag,
            factory: Factory(T)
        ) !Self {
            const flattened = try self.flatten(tag, factory);
            return try flattened.constantFold(factory);
        }

        pub fn simplifyChildren(self: Self, factory: Factory(T)) !Self {
            const flattened = try self.flatten(Context.tag, factory);

            const filtered = try flattened.filter(factory);
            if (filtered.list.items.len < 2) return filtered;

            const as_pow = try filtered.operands.asPow(factory);
            const collected = try as_pow.collectLikeTerms(factory);
            const folded = try collected.constantFold(factory);
            return Context.expFromOperands(folded);
        }

        pub fn constantFold(self: Self, factory: Factory(T)) !Self {
            var new_operands = Self.init(factory.allocator);
            var sum: T = Context.identity;
            for (self.list.items) |exp| {
                const folded_exp = try exp.constantFold(factory);
                if (folded_exp == .Const) {
                    sum = Context.compute(sum, folded_exp.Const.value);
                } else {
                    try new_operands.append(folded_exp);
                }
            }

            if (sum != Context.identity) {
                try new_operands.append(.constant(sum));
            }

            return new_operands;
        }
    };
}
