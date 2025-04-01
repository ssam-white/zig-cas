
const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Sub(comptime T: type) type {
    return struct {
        operands: []const Expression(T),

        const Self = @This();
        
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
            return .{ .Sub = .{ .operands = operands } };
        }

        pub const Factories = struct {
            pub fn subPtr(factory: Factory(T), operands: []const Expression(T)) !*Expression(T) {
                const operands_ptr = try factory.allocAll(operands);
                return try factory.create(.{ .Sub = .{ .operands = operands_ptr } });
            }
        };
    };
}
