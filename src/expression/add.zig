const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

pub fn Add(comptime T: type) type {
    return struct {
        operands: []const Expression(T),

        const Self = @This();
        
        pub fn deinit(self: Self, alloc: std.mem.Allocator) void {
            for (self.operands) |e| {
                e.deinit(alloc);
            }
            alloc.free(self.operands);
        }

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
            const dops = try factory.alloc.alloc(Expression(T), self.operands.len);
            for (self.operands, 0..) |exp, i| {
                dops[i] = try exp.d(var_name, factory);
            }
            return .{ .Add = .{ .operands = dops } };
        }
    };
}
