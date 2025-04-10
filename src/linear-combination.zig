const std = @import("std");
const Expression = @import("expression.zig").Expression;
const Factory = @import("factory.zig").Factory;

pub fn Term(comptime T: type) type {
    return struct {
        key: Expression(T),
        value: T,

        const Self = @This();
        
        fn toExpression(self: Self, factory: Factory(T)) !Expression(T) {
            return if (self.value == 0)
                .constant(0)
            else if (self.value == 1)
                self.key
            else try factory.mul(&.{
                .constant(self.value),
                self.key
            });
        }        
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
                try self.insert(exp);
            }
            return try self.toSlice(factory);
        }

        fn insert(
            self: *Self,
            exp: Expression(T)
        ) !void {
            if (self.indexOf(exp)) |i| {
                Context.addToTerm(&self.terms.items[i]);
            } else {
                try self.terms.append(.{
                    .key = exp,
                    .value = 1
                });
            }
        }

        fn toSlice(
            self: *Self,
            factory: Factory(T)
        ) ![]Expression(T) {
            const collected = try factory.alloc(self.terms.items.len);
            for (self.terms.items, 0..) |term, i| {
                collected[i] =
                    if (term.value == 0)
                        .constant(0)
                    else if (term.value == 1)
                        term.key
                    else if (term.key.eqlStructure(.constant(1)))
                        .constant(term.value)
                    else
                        try Context.termToExpression(term, factory);
            }
            return collected;
        }

        fn indexOf(
            self: *Self,
            target: Expression(T)
        ) ?usize {
            for (self.terms.items, 0..) |item, i| {
                if (target.eqlStructure(item.key)) {
                    return i;
                }
            }
            return null;
        }        
    };
}
