
pub fn QFP(comptime Pkg: type) type {
    _ = Pkg;
    return struct {
        pub const fp: Footprint = .{
        };
    };
}

pub fn QFN(comptime Pkg: type) type {
    _ = Pkg;
    return struct {
        pub const fp: Footprint = .{
        };
    };
}

pub fn DFN(comptime Pkg: type) type {
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

pub fn SO(comptime Pkg: type) type {
    _ = Pkg;
    return struct {
        pub const fp: Footprint = .{
        };
    };
}

pub fn SOJ(comptime Pkg: type) type {
    _ = Pkg;
    return struct {
        pub const fp: Footprint = .{
        };
    };
}

pub fn PLCC(comptime Pkg: type) type {
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
