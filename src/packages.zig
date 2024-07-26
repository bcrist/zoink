pub const jedec = @import("packages/jedec.zig");
pub const rc = @import("packages/rc.zig");

pub const SOT23 = jedec.TO_236H__MO_193G(3);
pub const SOT23_5 = jedec.TO_236H__MO_193G(5);
pub const SOT23_6 = jedec.TO_236H__MO_193G(6);
pub const SOT23_8 = jedec.TO_236H__MO_193G(8);

pub const SOT143 = jedec.TO_253D;

pub const SOT223 = jedec.TO_261AA;
pub const SOT223_5 = jedec.TO_261AB;

pub const SOJ_14 = jedec.MS_027A__MO_065A_077D_088A(14, 300);
pub const SOJ_16 = jedec.MS_027A__MO_065A_077D_088A(16, 300);
pub const SOJ_18 = jedec.MS_027A__MO_065A_077D_088A(18, 300);
pub const SOJ_20 = jedec.MS_027A__MO_065A_077D_088A(20, 300);
pub const SOJ_24 = jedec.MS_027A__MO_065A_077D_088A(24, 300);
pub const SOJ_26 = jedec.MS_027A__MO_065A_077D_088A(26, 300);
pub const SOJ_28_300 = jedec.MS_027A__MO_065A_077D_088A(28, 300);
pub const SOJ_32_300 = jedec.MS_027A__MO_065A_077D_088A(32, 300);
pub const SOJ_42_300 = jedec.MS_027A__MO_065A_077D_088A(42, 300);

pub const SOJ_28_400 = jedec.MS_027A__MO_065A_077D_088A(28, 400);
pub const SOJ_32_400 = jedec.MS_027A__MO_065A_077D_088A(32, 400);
pub const SOJ_34_400 = jedec.MS_027A__MO_065A_077D_088A(34, 400);
pub const SOJ_36_400 = jedec.MS_027A__MO_065A_077D_088A(36, 400);
pub const SOJ_40_400 = jedec.MS_027A__MO_065A_077D_088A(40, 400);
pub const SOJ_42_400 = jedec.MS_027A__MO_065A_077D_088A(42, 400);
pub const SOJ_44 = jedec.MS_027A__MO_065A_077D_088A(44, 400);

pub const PLCC_18 = jedec.MS_016A(18); // 5x4
pub const PLCC_22 = jedec.MS_016A(18); // 7x4
pub const PLCC_28_9x5 = jedec.MS_016A(18); // 9x5
pub const PLCC_32 = jedec.MS_016A(18); // 9x7

pub const PLCC_20L = jedec.MO_047B(20, .south_westmost);
pub const PLCC_28L = jedec.MO_047B(28, .south_westmost);
pub const PLCC_44L = jedec.MO_047B(44, .south_westmost);
pub const PLCC_52L = jedec.MO_047B(52, .south_westmost);
pub const PLCC_68L = jedec.MO_047B(68, .south_westmost);
pub const PLCC_84L = jedec.MO_047B(84, .south_westmost);
pub const PLCC_100L = jedec.MO_047B(100, .south_westmost);
pub const PLCC_124L = jedec.MO_047B(124, .south_westmost);

pub const PLCC_20M = jedec.MO_047B(20, .north_middle);
pub const PLCC_28M = jedec.MO_047B(28, .north_middle);
pub const PLCC_44M = jedec.MO_047B(44, .north_middle);
pub const PLCC_52M = jedec.MO_047B(52, .north_middle);
pub const PLCC_68M = jedec.MO_047B(68, .north_middle);
pub const PLCC_84M = jedec.MO_047B(84, .north_middle);
pub const PLCC_100M = jedec.MO_047B(100, .north_middle);
pub const PLCC_124M = jedec.MO_047B(124, .north_middle);

pub const SOIC_8_150 = jedec.MS_012G_02(8);
pub const SOIC_14_150 = jedec.MS_012G_02(14);
pub const SOIC_16_150 = jedec.MS_012G_02(16);
pub const SOIC_14_200 = jedec.MO_046B(14);
pub const SOIC_16_200 = jedec.MO_046B(16);
pub const SOIC_20_200 = jedec.MO_046B(20);
pub const SOIC_8_300 = jedec.MS_013G(8);
pub const SOIC_14_300 = jedec.MS_013G(14);
pub const SOIC_16_300 = jedec.MS_013G(16);
pub const SOIC_18_300 = jedec.MS_013G(18);
pub const SOIC_20_300 = jedec.MS_013G(20);
pub const SOIC_24_300 = jedec.MS_013G(24);
pub const SOIC_28_300 = jedec.MS_013G(28);
pub const SOIC_24_330 = jedec.MO_059B(24);
pub const SOIC_28_330 = jedec.MO_059B(28);
pub const SOIC_44_500 = jedec.MO_126B(44);
pub const SOIC_48_500 = jedec.MO_126B(48);

pub const TQFP_100_14mm = jedec.MS_026D(100, 14, 14, .thin);

pub const TSOP_II_32 = jedec.MS_024H(32, 1270);
pub const TSOP_II_44 = jedec.MS_024H(44, 800);

pub const SSOP_8 = jedec.MO_150B(8);
pub const SSOP_14 = jedec.MO_150B(14);
pub const SSOP_16 = jedec.MO_150B(16);
pub const SSOP_18 = jedec.MO_150B(18);
pub const SSOP_20 = jedec.MO_150B(20);
pub const SSOP_22 = jedec.MO_150B(22);
pub const SSOP_24 = jedec.MO_150B(24);
pub const SSOP_28_200 = jedec.MO_150B(28);
pub const SSOP_30_200 = jedec.MO_150B(30);
pub const SSOP_38_200 = jedec.MO_150B(38);
pub const SSOP_28_300 = jedec.MO_118B(28);
pub const SSOP_48 = jedec.MO_118B(48);
pub const SSOP_56 = jedec.MO_118B(56);
pub const SSOP_64 = jedec.MO_118B(64);

pub const TSSOP_14 = jedec.MO_153H(14, 650, .b);
pub const TSSOP_20 = jedec.MO_153H(20, 650, .b);
pub const TSSOP_48 = jedec.MO_153H(48, 500, .c);
pub const TSSOP_56 = jedec.MO_153H(56, 500, .c);

pub const TVSOP_14 = jedec.MO_194B(14);
pub const TVSOP_16 = jedec.MO_194B(16);
pub const TVSOP_20 = jedec.MO_194B(20);
pub const TVSOP_24 = jedec.MO_194B(24);
pub const TVSOP_48 = jedec.MO_194B(48);
pub const TVSOP_56 = jedec.MO_194B(56);
pub const TVSOP_80 = jedec.MO_194B(80);
pub const TVSOP_100 = jedec.MO_194B(100);

pub const FBGA_48 = jedec.MO_207AD;

pub const R1206 = rc._1206(550);
pub const R0805 = rc._0805(550);
pub const R0603 = rc._0603(450);
pub const R0402 = rc._0402(350);
pub const R0201 = rc._0201(230);

pub const C1206 = rc._1206(1750);
pub const C0805 = rc._0805(1350);
pub const C0603 = rc._0603(950);
pub const C0402 = rc._0402(550);
pub const C0201 = rc._0201(330);
