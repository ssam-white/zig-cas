const std = @import("std");
const Expression = @import("expression.zig").Expression;
const Factory = @import("factory.zig").Factory;

pub fn Term(comptime T: type) type {
    return struct {
        key: Expression(T),
        value: Expression(T),
    };
}

pub fn LinearCombination(
    comptime T: type,
    comptime Context: type
) type {
    return struct {
        terms: std.ArrayList(Term(T)),

        const Self = @This();

        pub fn init(alloc: std.mem.Allocator) Self {
            return .{ .terms = .init(alloc) };
        }

        pub fn deinit(self: Self) void {
            self.terms.deinit();
        }

        pub fn collect(
            self: *Self,
            operands: []Expression(T),
            factory: Factory(T)
        ) ![]Expression(T) {
            for (operands) |exp| {
                try self.insert(try exp.rewrite(factory), factory);
            }
            return try self.toSlice(factory);
        }

        fn insert(self: *Self, exp: Expression(T), factory: Factory(T)) !void {
            if (self.indexOf(exp)) |i| {
                try Context.addToTerm(&self.terms.items[i], exp, factory);
            } else {
                const new_term = try Context.termFromExpression(exp, factory);
                try self.terms.append(new_term);
            }
        }

        fn toSlice(
            self: *Self,
            factory: Factory(T)
        ) ![]Expression(T) {
            const collected = try factory.alloc(self.terms.items.len);
            for (self.terms.items, 0..) |term, i| {
                collected[i] =
                    if (term.value.eqlStructure(.constant(1)))
                        term.key
                    else try Context.termToExpression(term, factory);
            }
            return collected;
        }

        fn indexOf(
            self: *Self,
            target: Expression(T)
        ) ?usize {
            for (self.terms.items, 0..) |item, i| {
                if (Context.isMatch(item, target)) {
                    return i;
                }
            }
            return null;
        }        
    };
}
