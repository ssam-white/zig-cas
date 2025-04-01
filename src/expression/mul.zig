const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Mul(comptime T: type) type {
    return struct {
        operands: []const Expression(T),

        const Self = @This();

        pub fn eval(self: Self, args: Expression(T).Args) T {
            var prod = self.operands[0].eval(args);
            for (self.operands[1..]) |e| {
                prod *= e.eval(args);
            }
            return prod;
        }

        pub fn print(self: Self) void {
            std.debug.print("( ", .{});
            defer std.debug.print(" )", .{});
            
            if (self.operands.len == 0) return;
            self.operands[0].print();
            for (self.operands[1..]) |e| {
                std.debug.print(" * ", .{});
                e.print();
            }
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            const operands = try factory.alloc(self.operands.len);
            for (operands, 0..) |_, i| {
                const terms = try factory.alloc(self.operands.len);
                @memcpy(terms, self.operands);
                terms[i] = try self.operands[i].d(var_name, factory);
                operands[i] = .{ .Mul = .{ .operands = terms } };
            }
            return .{ .Mul = .{ .operands = operands } };
        }

        pub const Factories = struct {
            pub fn mulPtr(factory: Factory(T), operands: []const Expression(T)) !*Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return try factory.create(.{ .Mul = .{ .operands = operands_ptr } });
            }

            pub fn mul(factory: Factory(T), operands: []const Expression(T)) !Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return .{ .Mul = .{ .operands = operands_ptr } };
            }
        };
    };
}
