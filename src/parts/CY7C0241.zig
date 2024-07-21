base: Part.Base = .{
    .package = &pkg.tqfp100,
    .prefix = .U,
},

master: Net_ID = .unset,
left: Port = .unset,
right: Port = .unset,
pwr: Power = .{},

pub const Power = struct {
    gnd: [6]Net_ID = .{ .unset } ** 6,
    p5v: [3]Net_ID = .{ .unset } ** 3,

    pub const Decouple = parts.C0402_Decoupler;
};

pub const Port = struct {
    chip_enable_low: Net_ID = .unset,
    write_enable_low: Net_ID = .unset,
    output_enable_low: Net_ID = .unset,
    semaphore_enable_low: Net_ID = .unset,
    upper_byte_seelct_low: Net_ID = .unset,
    lower_byte_select_low: Net_ID = .unset,
    interrupt_low: Net_ID = .unset,
    busy_low: Net_ID = .unset,
    address: [12]Net_ID = .{ .unset } ** 12,
    data: Data = .{},
};

pub const Data = struct {
    lower: [9]Net_ID = .{ .unset } ** 9,
    upper: [9]Net_ID = .{ .unset } ** 9,
};

pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
    return switch (@intFromEnum(pin_id)) {
        62 => self.master,

        64 => self.left.busy_low,
        65 => self.left.interrupt_low,
        83 => self.left.lower_byte_select_low,
        84 => self.left.upper_byte_seelct_low,
        85 => self.left.chip_enable_low,
        86 => self.left.semaphore_enable_low,
        87 => self.left.write_enable_low,
        89 => self.left.output_enable_low,

        36 => self.right.output_enable_low,
        37 => self.right.write_enable_low,
        39 => self.right.semaphore_enable_low,
        40 => self.right.chip_enable_low,
        41 => self.right.upper_byte_seelct_low,
        42 => self.right.lower_byte_select_low,
        60 => self.right.interrupt_low,
        61 => self.right.busy_low,

        9 => self.pwr.gnd[0],
        12 => self.pwr.p5v[0],
        13 => self.pwr.gnd[1],
        17 => self.pwr.p5v[1],
        34 => self.pwr.gnd[2],
        38 => self.pwr.gnd[3],
        63 => self.pwr.gnd[4],
        88 => self.pwr.p5v[2],
        92 => self.pwr.gnd[5],

        66 => self.left.address[0],
        67 => self.left.address[1],
        68 => self.left.address[2],
        69 => self.left.address[3],
        70 => self.left.address[4],
        71 => self.left.address[5],
        76 => self.left.address[6],
        77 => self.left.address[7],
        78 => self.left.address[8],
        79 => self.left.address[9],
        80 => self.left.address[10],
        81 => self.left.address[11],

        59 => self.right.address[0],
        58 => self.right.address[1],
        57 => self.right.address[2],
        56 => self.right.address[3],
        55 => self.right.address[4],
        50 => self.right.address[5],
        49 => self.right.address[6],
        48 => self.right.address[7],
        47 => self.right.address[8],
        46 => self.right.address[9],
        45 => self.right.address[10],
        44 => self.right.address[11],

        90 => self.left.data.lower[0],
        91 => self.left.data.lower[1],
        93 => self.left.data.lower[2],
        94 => self.left.data.lower[3],
        95 => self.left.data.lower[4],
        96 => self.left.data.lower[5],
        97 => self.left.data.lower[6],
        98 => self.left.data.lower[7],
        3 => self.left.data.lower[8],
        99 => self.left.data.upper[9],
        100 => self.left.data.upper[10],
        5 => self.left.data.upper[11],
        6 => self.left.data.upper[12],
        7 => self.left.data.upper[13],
        8 => self.left.data.upper[14],
        10 => self.left.data.upper[15],
        11 => self.left.data.upper[16],
        4 => self.left.data.upper[17],

        14 => self.right.data.lower[0],
        15 => self.right.data.lower[1],
        16 => self.right.data.lower[2],
        18 => self.right.data.lower[3],
        19 => self.right.data.lower[4],
        20 => self.right.data.lower[5],
        21 => self.right.data.lower[6],
        26 => self.right.data.lower[7],
        22 => self.right.data.lower[8],
        27 => self.right.data.upper[9],
        28 => self.right.data.upper[10],
        29 => self.right.data.upper[11],
        30 => self.right.data.upper[12],
        31 => self.right.data.upper[13],
        32 => self.right.data.upper[14],
        33 => self.right.data.upper[15],
        35 => self.right.data.upper[16],
        23 => self.right.data.upper[17],

        1, 2, 24, 25, 43, 51, 52, 53, 54, 72, 73, 74, 75, 82 => .no_connect,
        else => unreachable,
    };
}

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const enums = @import("../enums.zig");
const power = @import("../power.zig");
const parts = @import("../parts.zig");
const pkg = @import("../packages.zig");
const Part = @import("../Part.zig");
const Package = @import("../Package.zig");
