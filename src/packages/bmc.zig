pub const BGA149 = struct {
    pub const pkg: Package = .{
        .default_footprint = fp.BGA(data, .normal),
        .has_pin = has_pin,
    };

    pub fn has_pin(pin: enums.Pin_ID) bool {
        return switch (@intFromEnum(pin)) {
            1...149 => true,
            else => false,
        };
    }

    pub const data: BGA_Data = .{
        .package_name = "BMC-149",
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
            .{ .ring = .{ // center 5x5
                .dist_from_edges = 8,
                .thickness = 3,
            }},
            .{ .individual = .{ .row = 3,  .col = 10, .mirror = .ns } },
            .{ .individual = .{ .row = 10, .col = 3,  .mirror = .we } },
            .{ .individual = .{ .row = 3,  .col = 3,  .mirror = .all } },
        },
        .exclude_balls = &.{
            .{ .rows = .{
                .dist_from_top = 5,
                .row_count = 1,
                .mirror = .ns,
            }},
            .{ .cols = .{
                .dist_from_left = 5,
                .col_count = 1,
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

            .{ .individual = .{ .row = 0, .col = 2, .mirror = .all } },
            .{ .individual = .{ .row = 0, .col = 3, .mirror = .all } },
            .{ .individual = .{ .row = 0, .col = 4, .mirror = .all } },
            .{ .individual = .{ .row = 1, .col = 4, .mirror = .all } },
            .{ .individual = .{ .row = 2, .col = 0, .mirror = .all } },
            .{ .individual = .{ .row = 3, .col = 0, .mirror = .all } },
            .{ .individual = .{ .row = 4, .col = 0, .mirror = .all } },
            .{ .individual = .{ .row = 4, .col = 1, .mirror = .all } },
        },
        .pin_name_format_func = kicad.format_pin_name(Pin_ID),
    };

    pub const Pin_ID = enum (u8) {
                                                     A6=1  , A7=2  , A8=3  ,                            A12=4  , A13=5  , A14=6  ,                                
                          B3=7  , B4=8  ,            B6=9  , B7=10 , B8=11 ,          B10=12 ,          B12=13 , B13=14 , B14=15 ,             B16=16 , B17=17 ,
                  C2=18 , C3=19 , C4=20 , C5=21 ,    C6=22 , C7=23 , C8=24 ,          C10=25 ,          C12=26 , C13=27 , C14=28 ,    C15=29 , C16=30 , C17=31 , C18=32 ,
                  D2=33 , D3=34 , D4=35 ,                                             D10=36 ,                                                 D16=37 , D17=38 , D18=39 ,
                          E3=40 ,                                                                                                                       E17=41 ,          

          F1=42 , F2=43 , F3=44 ,                                                                                                                       F17=45 , F18=46 , F19=47 ,
          G1=48 , G2=49 , G3=50 ,                                                                                                                       G17=51 , G18=52 , G19=53 ,
          H1=54 , H2=55 , H3=56 ,                                    H8=57 , H9=58 , H10=59 , H11=60 , H12=61 ,                                         H17=62 , H18=63 , H19=64 ,
                                                                     J8=65 , J9=66 , J10=67 , J11=68 , J12=69 ,
                  K2=70 , K3=71 , K4=72 ,                            K8=73 , K9=74 , K10=75 , K11=76 , K12=77 ,                                K16=78 , K17=79 , K18=80 ,
                                                                     L8=81 , L9=82 , L10=83 , L11=84 , L12=85 ,
          M1=86 , M2=87 , M3=88 ,                                    M8=89 , M9=90 , M10=91 , M11=92 , M12=93 ,                                         M17=94 , M18=95 , M19=96 ,
          N1=97 , N2=98 , N3=99 ,                                                                                                                       N17=100, N18=101, N19=102,
          P1=103, P2=104, P3=105,                                                                                                                       P17=106, P18=107, P19=108,

                          R3=109,                                                                                                                       R17=110,         
                  T2=111, T3=112, T4=113,                                             T10=114,                                                 T16=115, T17=116, T18=117,
                  U2=118, U3=119, U4=120, U5=121,    U6=122, U7=123, U8=124,          U10=125,          U12=126, U13=127, U14=128,    U15=129, U16=130, U17=131, U18=132,
                          V3=133, V4=134,            V6=135, V7=136, V8=137,          V10=138,          V12=139, V13=140, V14=141,             V16=142, V17=143,
                                                     W6=144, W7=145, W8=146,                            W12=147, W13=148, W14=149,

        pub fn from_generic(id: enums.Pin_ID) Pin_ID {
            return @enumFromInt(@intFromEnum(id));
        }
        pub fn generic(self: Pin_ID) enums.Pin_ID {
            return @enumFromInt(@intFromEnum(self));
        }
    };
};

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
                .col_count = 1,
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


/// A pogo-pin based programming harness system similar to tag-connect, but cheaper:
///      - uses 10x P50 pogo pins
///      - 3 pins are installed "backwards" to provide alignment
///          - inserted into through-holes on the target board
///      - 7 signal pins
///          - Usually power, ground, target presence sense, and up to 4 serial signals
///      - Requires a board area of approx. 6mm x 4.5mm 
///      - The land pattern on a board looks like a trident, hence the name
///      - When looking at the land pattern in a "portrait" orientation (trident pointing up)
///          - The land pattern should look like this:
///                        (O)
///                     1       7
///                         3
///                     2       6
///                         4
///                    (O)      (O)
///                         5
///          - The (O) indicates the position of the alignment holes
///          - Pin 3 (in center of pins 1, 2, 4, 6, and 7) should always be ground
///          - Note that the first two columns go from top to bottom, but the last column goes bottom to top.
///             - You can think of this as numbering counter-clockwise
pub const Trident = struct {
    pub const pkg: Package = .{
        .default_footprint = generate_footprint(),
        .has_pin = has_pin,
    };

    pub fn has_pin(pin: enums.Pin_ID) bool {
        return switch (@intFromEnum(pin)) {
            0...7 => true,
            else => false,
        };
    }

    fn generate_footprint() *const Footprint {
        @setEvalBranchQuota(100_000);
        var result: Footprint = .{
            .kind = .through_hole,
            .name = "Trident",
        };

        const pad_diameter_um: f64 = 889;
        const pitch_um: f64 = 1524;
        const offset_um: f64 = 2540;

        const hole_diameter_um: f64 = 760;
        const pth_diameter_um: f64 = 950;
        const hole_courtyard_radius_um: f64 = 900;

        const holes: [3]kicad.Location = .{
            .init_um(0, -5080),
            .init_um(-1778, -762),
            .init_um(1778, -762),
        };

        result.circles = &.{
            kicad.Circle {
                .center = holes[0],
                .end = .{
                    .x = .{ .um = holes[0].x.um, },
                    .y = .{ .um = holes[0].y.um  - hole_courtyard_radius_um, },
                },
                .layer = .courtyard_front,
                .stroke = .{
                    .width = .init_mm(0.01),
                },
            },
            kicad.Circle {
                .center = holes[1],
                .end = .{
                    .x = .{ .um = holes[1].x.um, },
                    .y = .{ .um = holes[1].y.um  - hole_courtyard_radius_um, },
                },
                .layer = .courtyard_front,
                .stroke = .{
                    .width = .init_mm(0.01),
                },
            },
            kicad.Circle {
                .center = holes[2],
                .end = .{
                    .x = .{ .um = holes[2].x.um, },
                    .y = .{ .um = holes[2].y.um  - hole_courtyard_radius_um, },
                },
                .layer = .courtyard_front,
                .stroke = .{
                    .width = .init_mm(0.01),
                },
            },
        };

        result.pads = &.{
            kicad.Pad {
                .pin = @enumFromInt(0),
                .kind = .through_hole,
                .location = holes[0],
                .w = .init_um(pth_diameter_um),
                .h = .init_um(pth_diameter_um),
                .hole_w = .init_um(hole_diameter_um),
                .hole_h = .init_um(hole_diameter_um),
                .shape = .oval,
                .layers = footprints.through_hole_layers,
                .copper_layers = .connected_and_outside_only,
                .teardrops = .{},
            },
            kicad.Pad {
                .pin = @enumFromInt(0),
                .kind = .through_hole,
                .location = holes[1],
                .w = .init_um(pth_diameter_um),
                .h = .init_um(pth_diameter_um),
                .hole_w = .init_um(hole_diameter_um),
                .hole_h = .init_um(hole_diameter_um),
                .shape = .oval,
                .layers = footprints.through_hole_layers,
                .copper_layers = .connected_and_outside_only,
                .teardrops = .{},
            },
            kicad.Pad {
                .pin = @enumFromInt(0),
                .kind = .through_hole,
                .location = holes[2],
                .w = .init_um(pth_diameter_um),
                .h = .init_um(pth_diameter_um),
                .hole_w = .init_um(hole_diameter_um),
                .hole_h = .init_um(hole_diameter_um),
                .shape = .oval,
                .layers = footprints.through_hole_layers,
                .copper_layers = .connected_and_outside_only,
                .teardrops = .{},
            },
            kicad.Pad {
                .pin = @enumFromInt(1),
                .kind = .smd,
                .location = .init_um(-pitch_um, -offset_um - pitch_um),
                .w = .init_um(pad_diameter_um),
                .h = .init_um(pad_diameter_um),
                .shape = .oval,
                .layers = footprints.smd_layers_no_paste,
                .copper_layers = .all,
                .teardrops = .{},
            },
            kicad.Pad {
                .pin = @enumFromInt(2),
                .kind = .smd,
                .location = .init_um(-pitch_um, -offset_um),
                .w = .init_um(pad_diameter_um),
                .h = .init_um(pad_diameter_um),
                .shape = .oval,
                .layers = footprints.smd_layers_no_paste,
                .copper_layers = .all,
                .teardrops = .{},
            },

            kicad.Pad {
                .pin = @enumFromInt(3),
                .kind = .smd,
                .location = .init_um(0, -pitch_um * 2),
                .w = .init_um(pad_diameter_um),
                .h = .init_um(pad_diameter_um),
                .shape = .oval,
                .layers = footprints.smd_layers_no_paste,
                .copper_layers = .all,
                .teardrops = .{},
            },
            kicad.Pad {
                .pin = @enumFromInt(4),
                .kind = .smd,
                .location = .init_um(0, -pitch_um),
                .w = .init_um(pad_diameter_um),
                .h = .init_um(pad_diameter_um),
                .shape = .oval,
                .layers = footprints.smd_layers_no_paste,
                .copper_layers = .all,
                .teardrops = .{},
            },
            kicad.Pad {
                .pin = @enumFromInt(5),
                .kind = .smd,
                .location = .init_um(0, 0),
                .w = .init_um(pad_diameter_um),
                .h = .init_um(pad_diameter_um),
                .shape = .oval,
                .layers = footprints.smd_layers_no_paste,
                .copper_layers = .all,
                .teardrops = .{},
            },

            kicad.Pad {
                .pin = @enumFromInt(6),
                .kind = .smd,
                .location = .init_um(pitch_um, -offset_um),
                .w = .init_um(pad_diameter_um),
                .h = .init_um(pad_diameter_um),
                .shape = .oval,
                .layers = footprints.smd_layers_no_paste,
                .copper_layers = .all,
                .teardrops = .{},
            },
            kicad.Pad {
                .pin = @enumFromInt(7),
                .kind = .smd,
                .location = .init_um(pitch_um, -offset_um - pitch_um),
                .w = .init_um(pad_diameter_um),
                .h = .init_um(pad_diameter_um),
                .shape = .oval,
                .layers = footprints.smd_layers_no_paste,
                .copper_layers = .all,
                .teardrops = .{},
            },
        };

        const final_result = comptime result;
        return &final_result;
    }
};


const BGA_Data = footprints.BGA_Data;
const fp = footprints;
const Footprint = kicad.Footprint;
const kicad = @import("../kicad.zig");
const footprints = @import("../footprints.zig");
const enums = @import("../enums.zig");
const Package = @import("../Package.zig");
const std = @import("std");
