const std = @import("std");
const Factory = @import("factory.zig").Factory;

const Const = @import("expression/const.zig").Const;
const Add = @import("expression/add.zig").Add;
const Mul = @import("expression/mul.zig").Mul;
const Pow = @import("expression/pow.zig").Pow;
const Variable = @import("expression/variable.zig").Variable;
const Log = @import("expression/log.zig").Log;

pub fn Expression(comptime T: type) type {
    return union(enum) {
        const Errors = error {
            DeriveError
        };

        Variable: Variable(T),
        Const: Const(T),
        Add: Add(T),
        Mul: Mul(T),
        Pow: Pow(T),
        Log: Log(T),

        const Self = @This();
        pub const Args = []const struct { []const u8, Self };
        
        pub fn deinit(self: Self, alloc: std.mem.Allocator) void {
            switch (self) {
                inline else => |e| e.deinit(alloc)
            }
        }

        pub fn eval(self: Self, args: Args) T {
            return switch (self) {
                inline else => |e| e.eval(args),
            };
        }

        pub fn print(self: Self) void {
            switch (self) {
                inline else => |e| e.print(),
            }
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) Errors!Self {
            return switch (self) {
                inline else => |e| e.d(var_name, factory) catch Errors.DeriveError
            };
        }
    };
}
