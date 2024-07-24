const dpsram = @import("parts/dpsram.zig");

// 4Kword
pub const CY7C024_A = dpsram.CY7C0xx(8, 12, .p5v,  C0402_Decoupler, TTL, pkg.TQFP_100_14mm);
pub const CY7C024_J = dpsram.CY7C0xx(8, 12, .p5v,  C0402_Decoupler, TTL, pkg.PLCC_84);
pub const CY7C024V  = dpsram.CY7C0xx(8, 12, .p3v3, C0402_Decoupler, LVTTL, pkg.TQFP_100_14mm);
pub const CY7C0241  = dpsram.CY7C0xx(9, 12, .p5v,  C0402_Decoupler, TTL, pkg.TQFP_100_14mm);
pub const CY7C0241V = dpsram.CY7C0xx(9, 12, .p3v3, C0402_Decoupler, LVTTL, pkg.TQFP_100_14mm);

// 8Kword
pub const CY7C025_A = dpsram.CY7C0xx(8, 13, .p5v,  C0402_Decoupler, TTL, pkg.TQFP_100_14mm);
pub const CY7C025_J = dpsram.CY7C0xx(8, 13, .p5v,  C0402_Decoupler, TTL, pkg.PLCC_84);
pub const CY7C025V  = dpsram.CY7C0xx(8, 13, .p3v3, C0402_Decoupler, LVTTL, pkg.TQFP_100_14mm);
pub const CY7C0251  = dpsram.CY7C0xx(9, 13, .p5v,  C0402_Decoupler, TTL, pkg.TQFP_100_14mm);
pub const CY7C0251V = dpsram.CY7C0xx(9, 13, .p3v3, C0402_Decoupler, LVTTL, pkg.TQFP_100_14mm);

// 16Kword
pub const CY7C026V = dpsram.CY7C0xx(8, 14, .p3v3, C0402_Decoupler, LVTTL, pkg.TQFP_100_14mm);
pub const CY7C036V = dpsram.CY7C0xx(9, 14, .p3v3, C0402_Decoupler, LVTTL, pkg.TQFP_100_14mm);

// 32Kword
pub const CY7C027V = dpsram.CY7C0xx(8, 15, .p3v3, C0402_Decoupler, LVTTL, pkg.TQFP_100_14mm);
pub const CY7C037V = dpsram.CY7C0xx(9, 15, .p3v3, C0402_Decoupler, LVTTL, pkg.TQFP_100_14mm);

// 64Kword
pub const CY7C028V = dpsram.CY7C0xx(8, 16, .p3v3, C0402_Decoupler, LVTTL, pkg.TQFP_100_14mm);
pub const CY7C038V = dpsram.CY7C0xx(9, 16, .p3v3, C0402_Decoupler, LVTTL, pkg.TQFP_100_14mm);

const sram = @import("parts/sram.zig");

pub const AS7C31025_T  = sram.Async_8b(17, power.Multi(2, 2, .p3v3, C0402_Decoupler), LVTTL, sram.Pins_8b_Alliance, pkg.TSOP_II_32);
pub const AS7C31025_TJ = sram.Async_8b(17, power.Multi(2, 2, .p3v3, C0402_Decoupler), LVTTL, sram.Pins_8b_Alliance, pkg.SOJ_32_300);
pub const AS7C31025_J  = sram.Async_8b(17, power.Multi(2, 2, .p3v3, C0402_Decoupler), LVTTL, sram.Pins_8b_Alliance, pkg.SOJ_32_400);
pub const AS7C1025_T  = sram.Async_8b(17, power.Multi(2, 2, .p5v, C0402_Decoupler), TTL, sram.Pins_8b_Alliance, pkg.TSOP_II_32);
pub const AS7C1025_TJ = sram.Async_8b(17, power.Multi(2, 2, .p5v, C0402_Decoupler), TTL, sram.Pins_8b_Alliance, pkg.SOJ_32_300);
pub const AS7C1025_J  = sram.Async_8b(17, power.Multi(2, 2, .p5v, C0402_Decoupler), TTL, sram.Pins_8b_Alliance, pkg.SOJ_32_400);

pub const GS71116TP = sram.Async_16b(16, power.Multi(2, 2, .p3v3, C0402_Decoupler), LVTTL, sram.Pins_16b_GSI, pkg.TSOP_II_44);
pub const GS71116J  = sram.Async_16b(16, power.Multi(2, 2, .p3v3, C0402_Decoupler), LVTTL, sram.Pins_16b_GSI, pkg.SOJ_44);
pub const GS71116U  = sram.Async_16b(16, power.Multi(2, 2, .p3v3, C0402_Decoupler), LVTTL, sram.Pins_16b_GSI, pkg.FBGA_48);

pub const GS72116TP = sram.Async_16b(17, power.Multi(2, 2, .p3v3, C0402_Decoupler), LVTTL, sram.Pins_16b_GSI, pkg.TSOP_II_44);
pub const GS72116J  = sram.Async_16b(17, power.Multi(2, 2, .p3v3, C0402_Decoupler), LVTTL, sram.Pins_16b_GSI, pkg.SOJ_44);
pub const GS72116U  = sram.Async_16b(17, power.Multi(2, 2, .p3v3, C0402_Decoupler), LVTTL, sram.Pins_16b_GSI, pkg.FBGA_48);

const _74 = @import("parts/74x.zig");

pub const SN74LVC00AD   = _74.x00(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SOIC_14);
pub const SN74LVC00ADB  = _74.x00(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SSOP_14);
pub const SN74LVC00APW  = _74.x00(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TSSOP_14);
pub const SN74LVC00ARGY = _74.x00(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.VQFN_14);

pub const SN74LVC02AD   = _74.x02(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SOIC_14);
pub const SN74LVC02ADB  = _74.x02(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SSOP_14);
pub const SN74LVC02APW  = _74.x02(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TSSOP_14);
pub const SN74LVC02ARGY = _74.x02(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.VQFN_14);

pub const SN74LVC08AD   = _74.x08(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SOIC_14);
pub const SN74LVC08ADB  = _74.x08(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SSOP_14);
pub const SN74LVC08APW  = _74.x08(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TSSOP_14);
pub const SN74LVC08ARGY = _74.x08(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.VQFN_14);

pub const SN74LVC32AD   = _74.x32(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SOIC_14);
pub const SN74LVC32ADB  = _74.x32(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SSOP_14);
pub const SN74LVC32APW  = _74.x32(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TSSOP_14);
pub const SN74LVC32ARGY = _74.x32(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.VQFN_14);

pub const SN74LVC86AD   = _74.x86(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SOIC_14);
pub const SN74LVC86ADB  = _74.x86(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SSOP_14);
pub const SN74LVC86APW  = _74.x86(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TSSOP_14);
pub const SN74LVC86ARGY = _74.x86(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.VQFN_14);

pub const SN74LVC541ADB  = _74.x541(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SSOP_20);
pub const SN74LVC541ADGV = _74.x541(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TVSOP_20);
pub const SN74LVC541ADW  = _74.x541(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SOIC_20);
pub const SN74LVC541APW  = _74.x541(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TSSOP_20);
pub const SN74LVC541ARGY = _74.x541(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.VQFN_20);

pub const SN74LVC573ADB  = _74.x573(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SSOP_20);
pub const SN74LVC573ADGV = _74.x573(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TVSOP_20);
pub const SN74LVC573ADW  = _74.x573(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SOIC_20);
pub const SN74LVC573APW  = _74.x573(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TSSOP_20);
pub const SN74LVC573ARGY = _74.x573(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.VQFN_20);

pub const SN74LVC574ADB  = _74.x574(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SSOP_20);
pub const SN74LVC574ADGV = _74.x574(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TVSOP_20);
pub const SN74LVC574ADW  = _74.x574(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SOIC_20);
pub const SN74LVC574APW  = _74.x574(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TSSOP_20);
pub const SN74LVC574ARGY = _74.x574(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.VQFN_20);


pub const SN74LVT16244BDL    = _74.x16244(.p3v3, C0402_Decoupler, LVTTL_5VT, pkg.SSOP_48, false);
pub const SN74LVT16244BDGG   = _74.x16244(.p3v3, C0402_Decoupler, LVTTL_5VT, pkg.TSSOP_48, false);
pub const SN74LVT16244BDGV   = _74.x16244(.p3v3, C0402_Decoupler, LVTTL_5VT, pkg.TVSOP_48, false);
pub const SN74LVTH16244BDL   = _74.x16244(.p3v3, C0402_Decoupler, LVTTL_5VT, pkg.SSOP_48, true);
pub const SN74LVTH16244BDGG  = _74.x16244(.p3v3, C0402_Decoupler, LVTTL_5VT, pkg.TSSOP_48, true);
pub const SN74LVTH16244BDGV  = _74.x16244(.p3v3, C0402_Decoupler, LVTTL_5VT, pkg.TVSOP_48, true);
pub const SN74LVC16244ADL    = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SSOP_48, false);
pub const SN74LVC16244ADGG   = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TSSOP_48, false);
pub const SN74LVC16244ADGV   = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TVSOP_48, false);
pub const SN74LVCH16244ADL   = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.SSOP_48, true);
pub const SN74LVCH16244ADGG  = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TSSOP_48, true);
pub const SN74LVCH16244ADGV  = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS_5VT, pkg.TVSOP_48, true);
pub const SN74ALVC16244ADL   = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS, pkg.SSOP_48, false);
pub const SN74ALVC16244ADGG  = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS, pkg.TSSOP_48, false);
pub const SN74ALVC16244ADGV  = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS, pkg.TVSOP_48, false);
pub const SN74ALVCH16244DL   = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS, pkg.SSOP_48, true);
pub const SN74ALVCH16244DGG  = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS, pkg.TSSOP_48, true);
pub const SN74ALVCH16244DGV  = _74.x16244(.p3v3, C0402_Decoupler, LVCMOS, pkg.TVSOP_48, true);


pub const SN74ABT16260DL    = _74.x16260(.p5v, C0402_Decoupler, TTL, pkg.SSOP_56, false);
pub const SN74ABTH16260DL   = _74.x16260(.p5v, C0402_Decoupler, TTL, pkg.SSOP_56, true);
pub const SN74ALVCH16260DL  = _74.x16260(.p3v3, C0402_Decoupler, LVCMOS, pkg.SSOP_56, true);
pub const SN74ALVCH16260DGG = _74.x16260(.p3v3, C0402_Decoupler, LVCMOS, pkg.TSSOP_56, true);
// 162260 is functionally identical to 16260, but has built-in series terminations on the B ports:
pub const SN74ABT162260DL    = _74.x16260(.p5v, C0402_Decoupler, TTL, pkg.SSOP_56, false);
pub const SN74ABTH162260DL   = _74.x16260(.p5v, C0402_Decoupler, TTL, pkg.SSOP_56, true);
pub const SN74ALVCH162260DL  = _74.x16260(.p3v3, C0402_Decoupler, LVCMOS, pkg.SSOP_56, true);
pub const SN74ALVCH162260DGG = _74.x16260(.p3v3, C0402_Decoupler, LVCMOS, pkg.TSSOP_56, true);

pub const SN74ALVC16721DL   = _74.x16721(.p3v3, C0402_Decoupler, LVCMOS, pkg.SSOP_56, false);
pub const SN74ALVC16721DGG  = _74.x16721(.p3v3, C0402_Decoupler, LVCMOS, pkg.TSSOP_56, false);
pub const SN74ALVCH16721DL  = _74.x16721(.p3v3, C0402_Decoupler, LVCMOS, pkg.SSOP_56, true);
pub const SN74ALVCH16721DGG = _74.x16721(.p3v3, C0402_Decoupler, LVCMOS, pkg.TSSOP_56, true);



const passive = @import("parts/passive.zig");
pub const Resistor = passive.Resistor;
pub const Cap = passive.Cap;
pub const Cap_Decoupler = passive.Cap_Decoupler;

pub const R1206 = Resistor(pkg.R1206);
pub const R0805 = Resistor(pkg.R0805);
pub const R0603 = Resistor(pkg.R0603);
pub const R0402 = Resistor(pkg.R0402);
pub const R0201 = Resistor(pkg.R0201);

pub const C1206 = Cap(pkg.C1206);
pub const C0805 = Cap(pkg.C0805);
pub const C0603 = Cap(pkg.C0603);
pub const C0402 = Cap(pkg.C0402);
pub const C0201 = Cap(pkg.C0201);

pub const C1206_Decoupler = Cap_Decoupler(pkg.C1206);
pub const C0805_Decoupler = Cap_Decoupler(pkg.C0805);
pub const C0603_Decoupler = Cap_Decoupler(pkg.C0603);
pub const C0402_Decoupler = Cap_Decoupler(pkg.C0402);
pub const C0201_Decoupler = Cap_Decoupler(pkg.C0201);


const LVCMOS = Voltage.LVCMOS;
const LVCMOS_5VT = Voltage.LVCMOS_5VT;
const CMOS = Voltage.CMOS;
const LVTTL = Voltage.LVTTL;
const LVTTL_5VT = Voltage.LVTTL_5VT;
const TTL = Voltage.TTL;
const Voltage = enums.Voltage;
const power = @import("power.zig");
const enums = @import("enums.zig");
const pkg = @import("packages.zig");
