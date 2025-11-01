pub const BGA151 = struct {
    pub const pkg: Package = .{
        .default_footprint = fp.BGA(data, .normal),
        .has_pin = has_pin,
    };

    pub fn has_pin(pin: enums.Pin_ID) bool {
        return switch (@intFromEnum(pin)) {
            1...151 => true,
            else => false,
        };
    }

    pub const data: BGA_Data = .{
        .package_name = "BMC-151",
        .body = .{
            .width  = .init_mm(22, 0.2),
            .height  = .init_mm(22, 0.2),
        },
        .max_z = .init_mm(4, 1.5),
        .ball_diameter = .init_mm(0.6, 0.05),
        .rows = 21,
        .cols = 21,
        .row_pitch = .init_mm(1, 0),
        .col_pitch = .init_mm(1, 0),
        .include_balls = &.{
            .{ .ring = .{
                .dist_from_edges = 0,
                .thickness = 3,
            }},
            .{ .ring = .{ // center 3x3
                .dist_from_edges = 9,
                .thickness = 2,
            }},
            .{ .individual = .{ .row = 3,  .col = 10, .mirror = .ns } },
            .{ .individual = .{ .row = 10, .col = 3,  .mirror = .we } },
            .{ .individual = .{ .row = 3,  .col = 3,  .mirror = .both } },
        },
        .exclude_balls = &.{
            .{ .rows = .{
                .dist_from_top = 5,
                .row_count = 1,
                .mirror = .ns,
            }},
            .{ .cols = .{
                .dist_from_left = 5,
                .row_count = 1,
                .mirror = .we,
            }},
            .{ .corners = .{
                .width = 2,
                .height = 2,
            }},
            .{ .individual = .{ .row = 0, .col = 9, .mirror = .ns } },
            .{ .individual = .{ .row = 0, .col = 10, .mirror = .ns } },
            .{ .individual = .{ .row = 0, .col = 11, .mirror = .ns } },
            .{ .individual = .{ .row = 1, .col = 9, .mirror = .ns } },
            .{ .individual = .{ .row = 1, .col = 11, .mirror = .ns } },
            .{ .individual = .{ .row = 2, .col = 9, .mirror = .ns } },
            .{ .individual = .{ .row = 2, .col = 11, .mirror = .ns } },

            .{ .individual = .{ .row = 9,  .col = 0, .mirror = .we } },
            .{ .individual = .{ .row = 10, .col = 0, .mirror = .we } },
            .{ .individual = .{ .row = 11, .col = 0, .mirror = .we } },
            .{ .individual = .{ .row = 9,  .col = 1, .mirror = .we } },
            .{ .individual = .{ .row = 11, .col = 1, .mirror = .we } },
            .{ .individual = .{ .row = 9,  .col = 2, .mirror = .we } },
            .{ .individual = .{ .row = 11, .col = 2, .mirror = .we } },

            .{ .individual = .{ .row = 0, .col = 2, .mirror = .both } },
            .{ .individual = .{ .row = 0, .col = 3, .mirror = .both } },
            .{ .individual = .{ .row = 0, .col = 4, .mirror = .both } },
            .{ .individual = .{ .row = 2, .col = 0, .mirror = .both } },
            .{ .individual = .{ .row = 3, .col = 0, .mirror = .both } },
            .{ .individual = .{ .row = 4, .col = 0, .mirror = .both } },
        },
        .pin_name_format_func = kicad.format_pin_name(Pin_ID),
    };

    pub const Pin_ID = enum (u8) {
                                                     A6=1  , A7=2  , A8=3  ,                            A12=4  , A13=5  , A14=6  ,    A15=7  , A16=8  , A17=9  ,
                          B3=10 , B4=11 , B5=12 ,    B6=13 , B7=14 , B8=15 ,          B10=16 ,          B12=17 , B13=18 , B14=19 ,    B15=20 , B16=21 , B17=22 ,
                  C2=23 , C3=24 , C4=25 , C5=26 ,    C6=27 , C7=28 , C8=29 ,          C10=30 ,          C12=31 , C13=32 , C14=33 ,    C15=34 , C16=35 , C17=36 , C18=37 , C19=38 ,
                  D2=39 , D3=40 , D4=41 ,                                             D10=42 ,                                                          D17=43 , D18=44 , D19=45 ,
                  E2=46 , E3=47 ,                                                                                                                       E17=48 , E18=49 , E19=50 ,

          F1=51 , F2=52 , F3=53 ,                                                                                                                       F17=54 , F18=55 , F19=56 ,
          G1=57 , G2=58 , G3=59 ,                                                                                                                       G17=60 , G18=61 , G19=62 ,
          H1=63 , H2=64 , H3=65 ,                                                                                                                       H17=66 , H18=67 , H19=68 ,
                                                                              J9=69 , J10=70 , J11=71 ,
                  K2=72 , K3=73 , K4=74 ,                                     K9=75 , K10=76 , K11=77 ,                                        K16=78 , K17=79 , K18=80 ,
                                                                              L9=81 , L10=82 , L11=83 ,
          M1=84 , M2=85 , M3=86 ,                                                                                                                       M17=87 , M18=88 , M19=89 ,
          N1=90 , N2=91 , N3=92 ,                                                                                                                       N17=93 , N18=94 , N19=95 ,
          P1=96 , P2=97 , P3=98 ,                                                                                                                       P17=99 , P18=100, P19=101,

          R1=102, R2=103, R3=104,                                                                                                                       R17=105, R18=106,
          T1=107, T2=108, T3=109,                                                     T10=110,                                                 T16=111, T17=112, T18=113,
          U1=114, U2=115, U3=116, U4=117, U5=118,    U6=119, U7=120, U8=121,          U10=122,          U12=123, U13=124, U14=125,    U15=126, U16=127, U17=128, U18=129,
                          V3=130, V4=131, V5=132,    V6=133, V7=134, V8=135,          V10=136,          V12=137, V13=138, V14=139,    V15=140, V16=141, V17=142,
                          W3=143, W4=144, W5=145,    W6=146, W7=147, W8=148,                            W12=149, W13=150, W14=151,

        pub fn from_generic(id: enums.Pin_ID) Pin_ID {
            return @enumFromInt(@intFromEnum(id));
        }
        pub fn generic(self: Pin_ID) enums.Pin_ID {
            return @enumFromInt(@intFromEnum(self));
        }
    };
};

const BGA_Data = footprints.BGA_Data;
const fp = footprints;
const kicad = @import("../kicad.zig");
const footprints = @import("../footprints.zig");
const enums = @import("../enums.zig");
const Package = @import("../Package.zig");
const std = @import("std");
