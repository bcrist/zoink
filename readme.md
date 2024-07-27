# _Zoink!_
### Programmer's Digital Design & Board Layout Tool

* Are you tired of painstakingly entering your designs in KiCAD's schematic editor before you can lay out the board?
* Have you ever wished that putting together a board design was less like photo editing and more like programming?
* Do you hate manually creating KiCAD symbols and footprints for every part you use, but just can't bring yourself to trust the default KiCAD component libraries?
* Are you wracked with disappointment when you send a board off to the fab only to notice that you forgot a decoupling cap somewhere?
* Do you wish KiCAD's ERC could check for logic level incompatibilities, bus contention, and behavioral correctness of your design?
* Are you addicted to writing Zig code?

If you answered "yes" to many of the above questions, you may be interested in _Zoink!_

## Usage
First, create a new zig project and add _Zoink!_ as a dependency with `zig fetch --save git+https://github.com/bcrist/zoink`.  Create a source file for your board and import `zoink`.

### Netlist Configuration
Create a function to configure your board's netlist like so:
```zig
pub fn configure(b: *Board) !void {
    // Define parts and nets here!
}
const Board = zoink.Board;
const zoink = @import("zoink");
```
You can add parts to the board with `Board.part(type)`.  This will return a pointer to an instance of the part type that you passed in.  You can find built-in parts in `zoink.parts`, or create your own.  Part types must be able to be initialized from `.{}`.  You must assign nets to all the non-power pins of the part after adding it to the board.  Failing to do this will generate an error when trying to use the board later.

You can use `Board.net(name)` to get or create a named net.  This returns a net ID that can be saved to a variable and used by value.  You can get or create a bus with `Board.bus(name, width)`.  A bus is just `[n]Net_ID` (or `[]const Net_ID`) so you can use zig's `++` operator to concatenate buses, and the normal slicing syntax to extract part of a bus.  You can also tell `b.bus()` to retrieve only part of the bus.  For example, to get the high nibble of an 8-bit bus: `b.bus("MY_BUS[4:7]", 4)`.  Indexes are 0-based, and both endpoints are inclusive.  Swapping the endpoints will reverse the order of the bits in the resulting array.  Note that the length parameter passed to `b.bus()` must match the number of bits being extracted.

### Automatic Power Connection & Decoupling Caps
Parts that contain a field named `pwr` will automatically have the signals in that struct connected to the power nets of the same name if they are not manually set.  Most parts will also automatically insert a decoupling capacitor for each non-ground signal.  This uses a special decoupling cap package, which has only 2 physical terminals, but 3 logical terminals.  This allows it to use a separate anonymous net to connect to the power pin, ensuring that the decoupling capacitor is actually placed right next to its associated power pin.

### Automatic Designation Assignment
Each part added to a board has a `base` field which allows you to assign a designator/name/value for the part, or override the default package/footprint.  Any parts that you don't manually assign a designator to will automatically have the next free number assigned.

### Remapping units/gates/bits
Some parts have multiple units/gates/bits that are logically interchangeable, but physically tied to specific pins.  In this case, the part should have a `remap` field, which is an array of integers.  Swapping values in this allows you to control which set of physical pins maps to a particular logical element.

### Behavior Tests
You can write zig tests that does a basic simulation of your circuit and assert that signals have the correct value under specific conditions.

For examples of writing behavior tests, see the various files in the `test` folder.


## Planned Features
* Programmatic package footprint generation
* Definition of board edges & filled zones in Zig code
* Board component placement in Zig code
* Export to KiCAD/pcbnew board file

## Stretch Goals / Brainstorm Area
* Integration with [Zig-LC4k](https://github.com/bcrist/Zig-LC4k)
* Constraint-based component placement
* Code-assisted routing
* Default trace widths by net
* Configurable axes (arbitrary angle; not just orthogonal X/Y)
* Realtime board preview (likely taking advantage of zig 0.14's `zig build --watch`)
* Preview-assisted component placement & movement
* Preview-assisted routing
* Trace spacing optimization
* Curved traces & teardrops
* "channels" - autoroute a whole bus at one time by specifying the bounding polygon and entry/exit points for each signal

## Non-Features
These are outside the scope of the project and likely will never be considered:
* Timing simulation
* Full analog SPICE simulation
* Export to KiCAD/eeschema files
* Import of KiCAD files
* CAM Export (gerbers/drills)
* 3D Board Rendering
