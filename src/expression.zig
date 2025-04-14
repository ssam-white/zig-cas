const std = @import("std");
const Factory = @import("factory.zig").Factory;

const Const = @import("expression/const.zig").Const;
const Add = @import("expression/add.zig").Add;
const Mul = @import("expression/mul.zig").Mul;
const Pow = @import("expression/pow.zig").Pow;
const Variable = @import("expression/variable.zig").Variable;
const Log = @import("expression/log.zig").Log;
const Div = @import("expression/div.zig").Div;
const Sub = @import("expression/sub.zig").Sub;
const Neg = @import("expression/neg.zig").Neg;

pub fn Expression(comptime T: type) type {
    return union(enum) {
        const Errors = error {
            DeriveError,
            RewriteError,
            FlatteningError,
            NoFlattenFunction,
            AsPowError,
            ConstantFoldError,
        };

        Variable: Variable(T),
        Const: Const(T),
        Add: Add(T),
        Mul: Mul(T),
        Pow: Pow(T),
        Log: Log(T),
        Div: Div(T),
        Sub: Sub(T),
        Neg: Neg(T),
        
        const Self = @This();

        pub const Args = []const struct { []const u8, Self };
        pub const Tag = std.meta.Tag(Self);

        pub const variable = Variable(T).initExp;
        pub const constant = Const(T).initExp;
        pub const pow = Pow(T).initExp;
        pub const div = Div(T).initExp;
        pub const log = Log(T).initExp;
        pub const add = Add(T).initExp;
        pub const mul = Mul(T).initExp;
        pub const sub = Sub(T).initExp;
        pub const neg = Neg(T).initExp;
        
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

        pub fn simplify(self: Self, factory: Factory(T)) Errors!Expression(T) {
            return switch (self) {
                inline else => |e| e.simplify(factory) catch Errors.RewriteError
            };
        }

        pub fn eqlStructure(self: Self, exp: Self) bool {
            return switch (self) {
                inline else => |e| e.eqlStructure(exp)
            };
        }

        pub fn flatten(self: Self, factory: Factory(T)) Errors!Expression(T) {
            return switch (self) {
                inline .Add, .Mul, .Sub
                => |e| e.flatten(factory) catch Errors.FlatteningError,
                inline else => Errors.NoFlattenFunction
            };
        }

        pub fn asPow(self: Self, factory: Factory(T)) Errors!Self {
                return switch(self) {
                    inline .Pow => self,
                    inline .Mul, .Div => |e| e.asPow(factory) catch return Errors.AsPowError,
                    inline else => Self.pow(
                        factory.create(self) catch return Errors.AsPowError,
                        factory.constantPtr(1) catch return Errors.AsPowError
                    )
                };
        }

        pub fn constantFold(self: Self, factory: Factory(T)) Errors!Expression(T) {
            return switch (self) {
                inline else => |e| e.constantFold(factory) catch Errors.ConstantFoldError
            };
        }

        pub fn isAnnihilated(self: Self) bool {
            if (self != .Mul) return true;
            
            for (self.Mul.operands.list.items) |e| {
                if (e.eqlStructure(.constant(0))) return true;
            }
            return false;
        }
    };
}
