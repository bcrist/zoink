
pub fn SQ(comptime Pkg: type) type {
    _ = Pkg;
    return struct {
        pub const fp: Footprint = .{
        };
    };
}

pub fn SD(comptime Pkg: type) type {
    _ = Pkg;
    return struct {
        pub const fp: Footprint = .{
        };
    };
}

pub fn BGA_Full(comptime Pkg: type) type {
    _ = Pkg;
    return struct {
        pub const fp: Footprint = .{
        };
    };
}

pub fn R(comptime Pkg: type) type {
    _ = Pkg;
    return struct {
        pub const fp: Footprint = .{
        };
    };
}

pub fn C(comptime Pkg: type) type {
    _ = Pkg;
    return struct {
        pub const fp: Footprint = .{
        };
    };
}


const Footprint = @import("../Footprint.zig");
