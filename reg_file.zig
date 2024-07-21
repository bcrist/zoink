pub fn configure(b: *Board) !void {

    const register_set_number = b.bus("RSN", 7);
    const write_address = b.bus("WA", 5);
    const local_bus = b.bus("L", 32);


    const low = b.part(CY7C0241);
    low.master = .gnd;
    low.left = .{
        .chip_enable_low = .gnd,
        .write_enable_low = .p5v,
        .output_enable_low = .gnd,
        .semaphore_enable_low = .p5v,
        .upper_byte_seelct_low = .gnd,
        .lower_byte_select_low = .gnd,
        .interrupt_low = .no_connect,
        .busy_low = .p5v,
        .address = write_address ++ register_set_number,
        .data = local_bus[0..16] ++ .{ .gnd } ** 2,
    };
    low.right = .{

    };


    const high = b.part(CY7C0241);
    high.master = .gnd;
    high.left = .{
    };
}

const CY7C0241 = zoink.parts.CY7C0241;
const Board = zoink.Board;
const zoink = @import("zoink");
