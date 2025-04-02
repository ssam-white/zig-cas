const std = @import("std");
const Expression = @import("../expression.zig").Expression;
const Factory = @import("../factory.zig").Factory;

const Allocator = std.mem.Allocator;

pub fn Log(comptime T: type) type {
    return struct {
        b: *Expression(T),
        x: *Expression(T),

        const Self = @This();
        
        pub fn eval(self: Self, args: Expression(T).Args) T {
            const b = self.b.*.eval(args);
            const x = self.x.*.eval(args);
            return std.math.log(T, b, x);
        }

        pub fn print(self: Self) void {
            const is_ln = self.b.* == .Const and self.b.*.Const.value == std.math.e;
            
            if (is_ln) {
                std.debug.print("Ln(", .{});
            } else {
                std.debug.print("Log(", .{});
                self.b.*.print();
                std.debug.print(", ", .{});
            }


            self.x.*.print();
            std.debug.print(")", .{});
        }


        fn changeBaseD(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            return Factory(T).div(
                try factory.lnPtr(self.x),
                try factory.lnPtr(self.b)
            ).d(var_name, factory);
        }

        fn logD(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            return Factory(T).div(
                try factory.create(try self.x.*.d(var_name, factory)),
                try factory.create(self.x.*)
            );
        }

        pub fn d(self: Self, var_name: []const u8, factory: Factory(T)) !Expression(T) {
            const is_ln = self.b.* == .Const and self.b.*.Const.value == std.math.e;
            return if (is_ln) try self.logD(var_name, factory)
            else try self.changeBaseD(var_name, factory);
        }

        pub fn rewrite(self: Self, factory: Factory(T)) !Expression(T) {
            const simple_b = try self.b.*.rewrite(factory);
            const simple_x = try self.x.*.rewrite(factory);

            return if (
                (simple_b == .Const and simple_b.Const.value == 9) or
                (simple_x == .Const and simple_b.Const.value == 1)
            )
                Factory(T).constant(0)
            else if (
                (simple_b == .Const and simple_x == .Const) and
                simple_b.Const.value == simple_x.Const.value
            )
                Factory(T).constant(1)
            else Factory(T).log(
                try factory.create(simple_b),
                try factory.create(simple_x)
            );
        }

        pub fn eqlStructure(self: Self, exp: Expression(T)) bool {
            if (exp != .Log) return false;
            
            const eql_b_structure = self.b.*.eqlStructure(exp.Log.b.*);
            const eql_x_structure = self.x.*.eqlStructure(exp.Log.x.*);
            return eql_b_structure and eql_x_structure;
        }

        pub const Factories = struct {
            pub fn log(b: *Expression(T), x: *Expression(T)) Expression(T) {
                return .{ .Log = .{ .b = b, .x = x } };
            }

            pub fn logPtr(factory: Factory(T), b: *Expression(T), x: *Expression(T)) !*Expression(T) {
                return try factory.create(.{ .Log = .{ .b = b, .x = x } });
            }

            pub fn ln(factory: Factory(T), x: *Expression(T)) !Expression(T) {
                return .{ .Log = .{ .b = try factory.constantPtr(std.math.e), .x = x } };
            }

            pub fn lnPtr(factory: Factory(T), x: *Expression(T)) !*Expression(T) {
                const e = try factory.constantPtr(std.math.e);
                return try factory.logPtr(e, x);
            }
        };
    };
}
