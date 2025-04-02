const std = @import("std");
const Expression = @import("expression.zig").Expression;
const Factory = @import("factory.zig").Factory;

pub fn LinearCombination(comptime T: type) type {
    return struct {
        const Term = struct {
            key: Expression(T),
            value: T,

            fn toExpression(self: Term, factory: Factory(T)) !Expression(T) {
                return if (self.value == 1)
                    self.key
                else try factory.mul(&.{
                    Factory(T).constant(self.value),
                    self.key
                });
            }        
        };

        terms: std.ArrayList(Term),

        const Self = @This();

        pub fn init(alloc: std.mem.Allocator) Self {
            return .{ .terms = std.ArrayList(Term).init(alloc) };
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
                self.terms.items[i].value += 1;
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
                collected[i] = try term.toExpression(factory);
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
