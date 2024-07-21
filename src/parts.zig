pub const CY7C0241 = @import("parts/CY7C0241.zig");

pub const AS7C31025_T  = mem.Async_SRAM_8b(17, power.Multi(2, .p3v3, C0402_Decoupler), LVTTL, mem.Pins_SRAM_8b_Alliance, pkg.TSOP_II_32);
pub const AS7C31025_TJ = mem.Async_SRAM_8b(17, power.Multi(2, .p3v3, C0402_Decoupler), LVTTL, mem.Pins_SRAM_8b_Alliance, pkg.SOJ_32_300);
pub const AS7C31025_J  = mem.Async_SRAM_8b(17, power.Multi(2, .p3v3, C0402_Decoupler), LVTTL, mem.Pins_SRAM_8b_Alliance, pkg.SOJ_32_400);
pub const AS7C1025_T  = mem.Async_SRAM_8b(17, power.Multi(2, .p5v, C0402_Decoupler), TTL, mem.Pins_SRAM_8b_Alliance, pkg.TSOP_II_32);
pub const AS7C1025_TJ = mem.Async_SRAM_8b(17, power.Multi(2, .p5v, C0402_Decoupler), TTL, mem.Pins_SRAM_8b_Alliance, pkg.SOJ_32_300);
pub const AS7C1025_J  = mem.Async_SRAM_8b(17, power.Multi(2, .p5v, C0402_Decoupler), TTL, mem.Pins_SRAM_8b_Alliance, pkg.SOJ_32_400);

pub const GS71116TP = mem.Async_SRAM_16b(16, power.Multi(2, .p3v3, C0402_Decoupler), LVTTL, mem.Pins_SRAM_16b_GSI, pkg.TSOP_II_44);
pub const GS71116J  = mem.Async_SRAM_16b(16, power.Multi(2, .p3v3, C0402_Decoupler), LVTTL, mem.Pins_SRAM_16b_GSI, pkg.SOJ_44);
pub const GS71116U  = mem.Async_SRAM_16b(16, power.Multi(2, .p3v3, C0402_Decoupler), LVTTL, mem.Pins_SRAM_16b_GSI, pkg.FBGA_48);

pub const GS72116TP = mem.Async_SRAM_16b(17, power.Multi(2, .p3v3, C0402_Decoupler), LVTTL, mem.Pins_SRAM_16b_GSI, pkg.TSOP_II_44);
pub const GS72116J  = mem.Async_SRAM_16b(17, power.Multi(2, .p3v3, C0402_Decoupler), LVTTL, mem.Pins_SRAM_16b_GSI, pkg.SOJ_44);
pub const GS72116U  = mem.Async_SRAM_16b(17, power.Multi(2, .p3v3, C0402_Decoupler), LVTTL, mem.Pins_SRAM_16b_GSI, pkg.FBGA_48);

pub const SN74LVC00AD   = _74.x00(.p3v3, C0402_Decoupler, CMOS33, pkg.SOIC_14);
pub const SN74LVC00ADB  = _74.x00(.p3v3, C0402_Decoupler, CMOS33, pkg.SSOP_14);
pub const SN74LVC00APW  = _74.x00(.p3v3, C0402_Decoupler, CMOS33, pkg.TSSOP_14);
pub const SN74LVC00ARGY = _74.x00(.p3v3, C0402_Decoupler, CMOS33, pkg.VQFN_14);

pub const SN74LVC02AD   = _74.x02(.p3v3, C0402_Decoupler, CMOS33, pkg.SOIC_14);
pub const SN74LVC02ADB  = _74.x02(.p3v3, C0402_Decoupler, CMOS33, pkg.SSOP_14);
pub const SN74LVC02APW  = _74.x02(.p3v3, C0402_Decoupler, CMOS33, pkg.TSSOP_14);
pub const SN74LVC02ARGY = _74.x02(.p3v3, C0402_Decoupler, CMOS33, pkg.VQFN_14);

pub const SN74LVC08AD   = _74.x08(.p3v3, C0402_Decoupler, CMOS33, pkg.SOIC_14);
pub const SN74LVC08ADB  = _74.x08(.p3v3, C0402_Decoupler, CMOS33, pkg.SSOP_14);
pub const SN74LVC08APW  = _74.x08(.p3v3, C0402_Decoupler, CMOS33, pkg.TSSOP_14);
pub const SN74LVC08ARGY = _74.x08(.p3v3, C0402_Decoupler, CMOS33, pkg.VQFN_14);

pub const SN74LVC32AD   = _74.x32(.p3v3, C0402_Decoupler, CMOS33, pkg.SOIC_14);
pub const SN74LVC32ADB  = _74.x32(.p3v3, C0402_Decoupler, CMOS33, pkg.SSOP_14);
pub const SN74LVC32APW  = _74.x32(.p3v3, C0402_Decoupler, CMOS33, pkg.TSSOP_14);
pub const SN74LVC32ARGY = _74.x32(.p3v3, C0402_Decoupler, CMOS33, pkg.VQFN_14);

pub const SN74LVC86AD   = _74.x86(.p3v3, C0402_Decoupler, CMOS33, pkg.SOIC_14);
pub const SN74LVC86ADB  = _74.x86(.p3v3, C0402_Decoupler, CMOS33, pkg.SSOP_14);
pub const SN74LVC86APW  = _74.x86(.p3v3, C0402_Decoupler, CMOS33, pkg.TSSOP_14);
pub const SN74LVC86ARGY = _74.x86(.p3v3, C0402_Decoupler, CMOS33, pkg.VQFN_14);

pub const SN74LVC541ADB  = _74.x541(.p3v3, C0402_Decoupler, CMOS33, pkg.SSOP_20);
pub const SN74LVC541ADGV = _74.x541(.p3v3, C0402_Decoupler, CMOS33, pkg.TVSOP_20);
pub const SN74LVC541ADW  = _74.x541(.p3v3, C0402_Decoupler, CMOS33, pkg.SOIC_20);
pub const SN74LVC541APW  = _74.x541(.p3v3, C0402_Decoupler, CMOS33, pkg.TSSOP_20);
pub const SN74LVC541ARGY = _74.x541(.p3v3, C0402_Decoupler, CMOS33, pkg.VQFN_20);

pub const SN74LVC573ADB  = _74.x573(.p3v3, C0402_Decoupler, CMOS33, pkg.SSOP_20);
pub const SN74LVC573ADGV = _74.x573(.p3v3, C0402_Decoupler, CMOS33, pkg.TVSOP_20);
pub const SN74LVC573ADW  = _74.x573(.p3v3, C0402_Decoupler, CMOS33, pkg.SOIC_20);
pub const SN74LVC573APW  = _74.x573(.p3v3, C0402_Decoupler, CMOS33, pkg.TSSOP_20);
pub const SN74LVC573ARGY = _74.x573(.p3v3, C0402_Decoupler, CMOS33, pkg.VQFN_20);

pub const SN74LVC574ADB  = _74.x574(.p3v3, C0402_Decoupler, CMOS33, pkg.SSOP_20);
pub const SN74LVC574ADGV = _74.x574(.p3v3, C0402_Decoupler, CMOS33, pkg.TVSOP_20);
pub const SN74LVC574ADW  = _74.x574(.p3v3, C0402_Decoupler, CMOS33, pkg.SOIC_20);
pub const SN74LVC574APW  = _74.x574(.p3v3, C0402_Decoupler, CMOS33, pkg.TSSOP_20);
pub const SN74LVC574ARGY = _74.x574(.p3v3, C0402_Decoupler, CMOS33, pkg.VQFN_20);


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

pub const Resistor = passive.Resistor;
pub const Cap = passive.Cap;
pub const Cap_Decoupler = passive.Cap_Decoupler;

const _74 = @import("parts/74x.zig");
const mem = @import("parts/mem.zig");
const passive = @import("parts/passive.zig");

const LVCMOS = Voltage.LVCMOS;
const CMOS33 = Voltage.CMOS33;
const CMOS = Voltage.CMOS;
const LVTTL = Voltage.LVTTL;
const TTL = Voltage.TTL;
const Voltage = enums.Voltage;
const power = @import("power.zig");
const enums = @import("enums.zig");
const pkg = @import("packages.zig");
