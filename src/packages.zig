pub const jedec = @import("packages/jedec.zig");
pub const rc = @import("packages/rc.zig");
pub const pga = @import("packages/pga.zig");

pub const DIP8 = jedec.MS_001D(8, "DIP-8");
pub const DIP14 = jedec.MS_001D(14, "DIP-14");
pub const DIP16 = jedec.MS_001D(16, "DIP-16");
pub const DIP18 = jedec.MS_001D(18, "DIP-18");
pub const DIP20_300 = jedec.MS_001D(20, "DIP-20 (300 mil)");
pub const DIP22_300 = jedec.MS_001D(22, "DIP-22 (300 mil)");
pub const DIP24_300 = jedec.MS_001D(24, "DIP-24 (300 mil)");
pub const DIP28_300 = jedec.MS_001D(28, "DIP-28 (300 mil)");
pub const DIP20_400 = jedec.MS_015A(20, 400, "DIP-20 (400 mil)");
pub const DIP22_400 = jedec.MS_010C(22, "DIP-22 (400 mil)");
pub const DIP24_400 = jedec.MS_010C(24, "DIP-24 (400 mil)");
pub const DIP28_400 = jedec.MS_010C(28, "DIP-28 (400 mil)");
pub const DIP32_400 = jedec.MS_010C(32, "DIP-32 (400 mil)");
pub const DIP24_600 = jedec.MS_011B(24, "DIP-24 (600 mil)");
pub const DIP28_600 = jedec.MS_011B(28, "DIP-28 (600 mil)");
pub const DIP32_600 = jedec.MS_015A(32, 600, "DIP-32 (600 mil)");
pub const DIP36 = jedec.MS_015A(36, 600, "DIP-36");
pub const DIP40 = jedec.MS_011B(40, "DIP-40");
pub const DIP48 = jedec.MS_015A(48, 600, "DIP-48");
pub const DIP52 = jedec.MS_015A(52, 600, "DIP-52");
pub const DIP50 = jedec.MS_015A(50, 900, "DIP-50");
pub const DIP64 = jedec.MS_015A(64, 900, "DIP-64");

pub const PGA68 = pga.PGA68;

pub const SOT23 = jedec.TO_236H__MO_193G(3, "SOT23");
pub const SOT23_5 = jedec.TO_236H__MO_193G(5, "SOT23-5");
pub const SOT23_6 = jedec.TO_236H__MO_193G(6, "SOT23-6");
pub const SOT23_8 = jedec.TO_236H__MO_193G(8, "SOT23-8");

pub const SOT143 = jedec.TO_253D;

pub const SOT223 = jedec.TO_261AA;
pub const SOT223_5 = jedec.TO_261AB;

pub const SOJ_14 = jedec.MS_027A__MO_065A_077D_088A(14, 300, "SOJ-14");
pub const SOJ_16 = jedec.MS_027A__MO_065A_077D_088A(16, 300, "SOJ-16");
pub const SOJ_18 = jedec.MS_027A__MO_065A_077D_088A(18, 300, "SOJ-18");
pub const SOJ_20 = jedec.MS_027A__MO_065A_077D_088A(20, 300, "SOJ-20");
pub const SOJ_24 = jedec.MS_027A__MO_065A_077D_088A(24, 300, "SOJ-24");
pub const SOJ_26 = jedec.MS_027A__MO_065A_077D_088A(26, 300, "SOJ-26");
pub const SOJ_28_300 = jedec.MS_027A__MO_065A_077D_088A(28, 300, "SOJ-28 (300 mil)");
pub const SOJ_32_300 = jedec.MS_027A__MO_065A_077D_088A(32, 300, "SOJ-32 (300 mil)");
pub const SOJ_42_300 = jedec.MS_027A__MO_065A_077D_088A(42, 300, "SOJ-42 (300 mil)");
pub const SOJ_28_400 = jedec.MS_027A__MO_065A_077D_088A(28, 400, "SOJ-28 (400 mil)");
pub const SOJ_32_400 = jedec.MS_027A__MO_065A_077D_088A(32, 400, "SOJ-32 (400 mil)");
pub const SOJ_34_400 = jedec.MS_027A__MO_065A_077D_088A(34, 400, "SOJ-34 (400 mil)");
pub const SOJ_36_400 = jedec.MS_027A__MO_065A_077D_088A(36, 400, "SOJ-36 (400 mil)");
pub const SOJ_40_400 = jedec.MS_027A__MO_065A_077D_088A(40, 400, "SOJ-40 (400 mil)");
pub const SOJ_42_400 = jedec.MS_027A__MO_065A_077D_088A(42, 400, "SOJ-42 (400 mil)");
pub const SOJ_44 = jedec.MS_027A__MO_065A_077D_088A(44, 400, "SOJ-44");

pub const PLCC_18 = jedec.MS_016A(18, "PLCC-18"); // 5x4
pub const PLCC_22 = jedec.MS_016A(22, "PLCC-22"); // 7x4
pub const PLCC_28_9x5 = jedec.MS_016A(28, "PLCC-28 (9 mm x 5 mm)"); // 9x5
pub const PLCC_32 = jedec.MS_016A(32, "PLCC-32"); // 9x7

pub const PLCC_20L = jedec.MO_047B(20, .south_westmost, "PLCC-20L");
pub const PLCC_28L = jedec.MO_047B(28, .south_westmost, "PLCC-28L");
pub const PLCC_44L = jedec.MO_047B(44, .south_westmost, "PLCC-44L");
pub const PLCC_52L = jedec.MO_047B(52, .south_westmost, "PLCC-52L");
pub const PLCC_68L = jedec.MO_047B(68, .south_westmost, "PLCC-68L");
pub const PLCC_84L = jedec.MO_047B(84, .south_westmost, "PLCC-84L");
pub const PLCC_100L = jedec.MO_047B(100, .south_westmost, "PLCC-100L");
pub const PLCC_124L = jedec.MO_047B(124, .south_westmost, "PLCC-124L");

pub const PLCC_20M = jedec.MO_047B(20, .west_middle, "PLCC-20M");
pub const PLCC_28M = jedec.MO_047B(28, .west_middle, "PLCC-28M");
pub const PLCC_44M = jedec.MO_047B(44, .west_middle, "PLCC-44M");
pub const PLCC_52M = jedec.MO_047B(52, .west_middle, "PLCC-52M");
pub const PLCC_68M = jedec.MO_047B(68, .west_middle, "PLCC-68M");
pub const PLCC_84M = jedec.MO_047B(84, .west_middle, "PLCC-84M");
pub const PLCC_100M = jedec.MO_047B(100, .west_middle, "PLCC-100M");
pub const PLCC_124M = jedec.MO_047B(124, .west_middle, "PLCC-124M");

pub const PLCC_32_PGA = pga.PLCC(9, 7);
pub const PLCC_28M_PGA = pga.PLCC(7, 7);
pub const PLCC_44M_PGA = pga.PLCC(11, 11);
pub const PLCC_52M_PGA = pga.PLCC(13, 13);
pub const PLCC_68M_PGA = pga.PLCC(17, 17);
pub const PLCC_84M_PGA = pga.PLCC(21, 21);

pub const SOIC_8_150 = jedec.MS_012G_02(8, "SOIC-8 (150 mil)");
pub const SOIC_14_150 = jedec.MS_012G_02(14, "SOIC-14 (150 mil)");
pub const SOIC_16_150 = jedec.MS_012G_02(16, "SOIC-16 (150 mil)");
pub const SOIC_14_200 = jedec.MO_046B(14, "SOIC-14 (200 mil)");
pub const SOIC_16_200 = jedec.MO_046B(16, "SOIC-16 (200 mil)");
pub const SOIC_20_200 = jedec.MO_046B(20, "SOIC-20 (200 mil)");
pub const SOIC_8_300 = jedec.MS_013G(8, "SOIC-8 (300 mil)");
pub const SOIC_14_300 = jedec.MS_013G(14, "SOIC-14 (300 mil)");
pub const SOIC_16_300 = jedec.MS_013G(16, "SOIC-16 (300 mil)");
pub const SOIC_18_300 = jedec.MS_013G(18, "SOIC-18 (300 mil)");
pub const SOIC_20_300 = jedec.MS_013G(20, "SOIC-20 (300 mil)");
pub const SOIC_24_300 = jedec.MS_013G(24, "SOIC-24 (300 mil)");
pub const SOIC_28_300 = jedec.MS_013G(28, "SOIC-28 (300 mil)");
pub const SOIC_24_330 = jedec.MO_059B(24, "SOIC-24 (330 mil)");
pub const SOIC_28_330 = jedec.MO_059B(28, "SOIC-28 (330 mil)");
pub const SOIC_44_500 = jedec.MO_126B(44, "SOIC-44 (500 mil)");
pub const SOIC_48_500 = jedec.MO_126B(48, "SOIC-48 (500 mil)");

pub const TQFP_44_10mm = jedec.MS_026D(44, 10, 10, .thin, "TQFP-44 (10mm)");
pub const TQFP_48_7mm = jedec.MS_026D(48, 7, 7, .thin, "TQFP-48 (7mm)");
pub const TQFP_100_14mm = jedec.MS_026D(100, 14, 14, .thin, "TQFP-100 (14mm)");
pub const LQFP_100_14mm = jedec.MS_026D(100, 14, 14, .low_profile, "LQFP-100 (14mm)");
pub const LQFP_128_14mm = jedec.MS_026D(128, 14, 14, .low_profile, "LQFP-128 (14mm)");
pub const LQFP_144_20mm = jedec.MS_026D(144, 20, 20, .low_profile, "LQFP-144 (20mm)");

pub const TSOP_II_32 = jedec.MS_024H(32, 1270, "TSOP-II-32");
pub const TSOP_II_44 = jedec.MS_024H(44, 800, "TSOP-II-44");

pub const SSOP_8 = jedec.MO_150B(8, "SSOP-8");
pub const SSOP_14 = jedec.MO_150B(14, "SSOP-14");
pub const SSOP_16 = jedec.MO_150B(16, "SSOP-16");
pub const SSOP_18 = jedec.MO_150B(18, "SSOP-18");
pub const SSOP_20 = jedec.MO_150B(20, "SSOP-20");
pub const SSOP_22 = jedec.MO_150B(22, "SSOP-22");
pub const SSOP_24 = jedec.MO_150B(24, "SSOP-24");
pub const SSOP_28_200 = jedec.MO_150B(28, "SSOP-28 (200 mil)");
pub const SSOP_30_200 = jedec.MO_150B(30, "SSOP-30 (200 mil)");
pub const SSOP_38_200 = jedec.MO_150B(38, "SSOP-38 (200 mil)");
pub const SSOP_28_300 = jedec.MO_118B(28, "SSOP-28 (300 mil)");
pub const SSOP_48 = jedec.MO_118B(48, "SSOP-48");
pub const SSOP_56 = jedec.MO_118B(56, "SSOP-56");
pub const SSOP_64 = jedec.MO_118B(64, "SSOP-64");

pub const TSSOP_14 = jedec.MO_153H(14, 650, .b, "TSSOP-14");
pub const TSSOP_16 = jedec.MO_153H(16, 650, .b, "TSSOP-16");
pub const TSSOP_20 = jedec.MO_153H(20, 650, .b, "TSSOP-20");
pub const TSSOP_48 = jedec.MO_153H(48, 500, .c, "TSSOP-48");
pub const TSSOP_56 = jedec.MO_153H(56, 500, .c, "TSSOP-56");

pub const TVSOP_14 = jedec.MO_194B(14, "TVSOP-14");
pub const TVSOP_16 = jedec.MO_194B(16, "TVSOP-16");
pub const TVSOP_20 = jedec.MO_194B(20, "TVSOP-20");
pub const TVSOP_24 = jedec.MO_194B(24, "TVSOP-24");
pub const TVSOP_48 = jedec.MO_194B(48, "TVSOP-48");
pub const TVSOP_56 = jedec.MO_194B(56, "TVSOP-56");
pub const TVSOP_80 = jedec.MO_194B(80, "TVSOP-80");
pub const TVSOP_100 = jedec.MO_194B(100, "TVSOP-100");

pub const BGA_48_6mm_8mm = jedec.MO_207AD;

pub const lattice = @import("packages/lattice.zig");

pub const BGA_p050_56_6mm = lattice.csBGA56;
pub const BGA_p050_64_5mm = lattice.csBGA64;
pub const BGA_p050_132_8mm = lattice.csBGA132;
pub const BGA_p050_144_7mm = lattice.csBGA144;

pub const BGA_p040_64_4mm = lattice.ucBGA64;
pub const BGA_p040_132_6mm = lattice.ucBGA132;

pub const R1206 = rc._1206(550, "R1206");
pub const R0805 = rc._0805(550, "R0805");
pub const R0603 = rc._0603(450, "R0603");
pub const R0402 = rc._0402(350, "R0402");
pub const R0201 = rc._0201(230, "R0201");

pub const C1206 = rc._1206(1750, "C1206");
pub const C0805 = rc._0805(1350, "C0805");
pub const C0603 = rc._0603(950, "C0603");
pub const C0402 = rc._0402(550, "C0402");
pub const C0201 = rc._0201(330, "C0201");
