// Modified Nodal Analysis for solving voltages in resistive circuits
// uses naive linear algebra algorithms, so performance on very large circuits may be poor.
// since our use case is mostly about verifying voltages in digital circuits, there's usually very few interconnected nodes.
// N.B. this doesn't support capacitors, inductors, or nonlinear elements like diodes.
pub const Solver = struct {
    allocator: std.mem.Allocator,
    matrix: Matrix,
    power_nodes: []f32,
    nets: []Net_ID,
    results: []f32,

    pub fn init(allocator: std.mem.Allocator, power_nodes: []f32, nets: []Net_ID) !Solver {
        const total_nodes = power_nodes.len + nets.len;
        const matrix_dim: u32 = @intCast(total_nodes + power_nodes.len);
        var m = try Matrix.init_zeroes(allocator, matrix_dim, matrix_dim);
        errdefer m.deinit(allocator);

        for (0..power_nodes.len) |i| {
            m.set(total_nodes + i, i, 1.0);
            m.set(i, total_nodes + i, 1.0);
        }

        return .{
            .allocator = allocator,
            .matrix = m,
            .power_nodes = power_nodes,
            .nets = nets,
            .results = &.{},
        };
    }

    pub fn deinit(solver: *Solver) void {
        solver.matrix.deinit(solver.allocator);
        if (solver.results.len > 0) {
            solver.allocator.free(solver.results);
        }
    }

    pub fn add_resistor_to_power(solver: *Solver, resistance: f32, net: Net_ID, v: f32) void {
        if (solver.find_node_index(net)) |net_node| {
            solver.add_resistor(resistance, net_node, solver.find_power_node_index(v));
        }
    }

    pub fn add_resistor_between_nets(solver: *Solver, resistance: f32, net_a: Net_ID, net_b: Net_ID) void {
        if (solver.find_node_index(net_a)) |node_a| {
            solver.add_resistor(resistance, node_a, solver.find_node_index(net_b));
        } else if (solver.find_node_index(net_b)) |node_b| {
            solver.add_resistor(resistance, node_b, null);
        }
    }

    fn add_resistor(solver: *Solver, resistance: f32, node_a: usize, maybe_node_b: ?usize) void {
        std.debug.assert(solver.results.len == 0);
        const conductance = 1.0 / resistance;
        solver.matrix.inc(node_a, node_a, conductance);
        if (maybe_node_b) |node_b| {
            solver.matrix.inc(node_b, node_b, conductance);
            solver.matrix.inc(node_a, node_b, -conductance);
            solver.matrix.inc(node_b, node_a, -conductance);
        }
    }

    pub fn solve(solver: *Solver) !void {
        std.debug.assert(solver.results.len == 0);
        try solver.matrix.invert(solver.allocator);
        var results = try solver.allocator.alloc(f32, solver.matrix.width * 2);
        solver.results = results;

        const total_nodes = solver.power_nodes.len + solver.nets.len;
        for (0..total_nodes) |i| {
            results[solver.matrix.width + i] = 0.0;
        }
        for (total_nodes.., solver.power_nodes) |i, v| {
            results[solver.matrix.width + i] = v;
        }

        solver.matrix.multiply_vector(results[solver.matrix.width..], results[0..solver.matrix.width]);
    }

    pub fn get_net_voltage(solver: *const Solver, net: Net_ID) Voltage {
        std.debug.assert(solver.results.len > 0);
        if (net.is_power()) return .from_net(net);
        return .from_float(solver.results[solver.find_node_index(net).?]);
    }

    fn find_power_node_index(solver: *const Solver, v: f32) ?usize {
        for (0.., solver.power_nodes) |i, power_v| {
            if (v == power_v) return i;
        }
        return null;
    }

    fn find_node_index(solver: *const Solver, net: Net_ID) ?usize {
        if (net.is_power()) {
            return solver.find_power_node_index(Voltage.from_net(net).as_float());
        } else for (solver.power_nodes.len.., solver.nets) |i, solver_net| {
            if (net == solver_net) return i;
        }
        return null;
    }
};

const Matrix = struct {
    width: u32,
    height: u32,
    elements: []f32,

    pub fn init_identity(allocator: std.mem.Allocator, dim: u32) !Matrix {
        const elements = try allocator.alloc(f32, dim * dim);
        var i: usize = 0;
        for (0..dim) |row| {
            for (0..dim) |col| {
                elements[i] = if (row == col) 1 else 0;
                i += 1;
            }
        }
        return .{
            .width = dim,
            .height = dim,
            .elements = elements,
        };
    }

    pub fn init_zeroes(allocator: std.mem.Allocator, width: u32, height: u32) !Matrix {
        const elements = try allocator.alloc(f32, width * height);
        @memset(elements, 0.0);
        return .{
            .width = width,
            .height = height,
            .elements = elements,
        };
    }

    pub fn deinit(matrix: *Matrix, allocator: std.mem.Allocator) void {
        allocator.free(matrix.elements);
    }

    pub fn get(matrix: Matrix, col: usize, row: usize) f32 {
        return matrix.elements[row * matrix.width + col];
    }

    pub fn set(matrix: *Matrix, col: usize, row: usize, v: f32) void {
        matrix.elements[row * matrix.width + col] = v;
    }

    pub fn inc(matrix: *Matrix, col: usize, row: usize, v: f32) void {
        matrix.elements[row * matrix.width + col] += v;
    }

    pub fn swap_rows(matrix: *Matrix, r1: usize, r2: usize) void {
        for (0..matrix.width) |col| {
            const temp = matrix.get(col, r1);
            matrix.set(col, r1, matrix.get(col, r2));
            matrix.set(col, r2, temp);
        }
    }

    pub fn scale_row(matrix: *Matrix, row: usize, k: f32) void {
        for (0..matrix.width) |col| {
            matrix.set(col, row, matrix.get(col, row) * k);
        }
    }

    pub fn multiply_vector(matrix: *Matrix, vector: []const f32, result: []f32) void {
        std.debug.assert(vector.len == matrix.width);
        @memset(result, 0.0);
        for (0.., result) |row, *r| {
            for (0..matrix.width) |col| {
                r.* += matrix.get(col, row) * vector[col];
            }
        }
    }

    pub fn invert(matrix: *Matrix, temp: std.mem.Allocator) !void {
        std.debug.assert(matrix.width == matrix.height);
        const n = matrix.width;

        // create temporary augmented matrix:
        var a: Matrix = try .init_zeroes(temp, n * 2, n);
        defer a.deinit(temp);

        for (0..n) |col| {
            for (0..n) |row| {
                a.set(col, row, matrix.get(col, row));
            }
        }
        for (0..n) |i| {
            a.set(n + i, i, 1);
        }

        // gaussian elimination:
        for (0..n) |i| {
            const pivot_row = pivot_row: {
                var pivot = i;
                var mag = @abs(a.get(i, i));
                for (i + 1 .. n) |row| {
                    const row_mag = @abs(a.get(i, row));
                    if (row_mag > mag) {
                        pivot = row;
                        mag = row_mag;
                    }
                }
                break :pivot_row pivot;
            };

            const pivot_value = a.get(i, pivot_row);

            // TODO may need to adjust this
            if (@abs(pivot_value) <= 1.0/10_000_000.0) return error.Noninvertible;

            if (pivot_row != i) a.swap_rows(pivot_row, i);
            if (pivot_value != 1) a.scale_row(i, 1/pivot_value);

            for (0..n) |row| {
                if (row == i) continue;
                const f = -a.get(i, row);
                for (0..a.width) |col| {
                    a.inc(col, row, f * a.get(col, i));
                }
            }
        }

        for (0..n) |col| {
            for (0..n) |row| {
                matrix.set(col, row, a.get(n + col, row));
            }
        }
    }
};

const Voltage = enums.Voltage;
const Net_ID = enums.Net_ID;
const enums = @import("enums.zig");
const std = @import("std");
