# Zoink!
### Programmatic Digital Design & Board Layout

Are you tired of painstakingly entering your designs in KiCAD's schematic editor before you can lay out the board?
Have you ever wished that putting together a board design was less like photo editing and more like programming?
Do you hate manually creating KiCAD symbols and footprints for every part you use but just can't bring yourself to trust the default KiCAD component libraries?
Are your wracked with disappointment when you send a board off to the fab only to notice that you forgot a decoupling cap somewhere?
Do you wish KiCAD's ERC could check for logic level incompatibilities, bus contention, and behavioral correctness of your design?
Are you addicted to writing Zig code?

If you answered "yes" to many of the above questions, you may be interested in _Zoink!_

## Current Features
* Circuit/netlist specification in Zig code
* Limited built-in component library 
* Automatic connection of power pins and insertion of decoupling caps
* Automatic component designation assignment
* Framework for writing ERC validation tests in Zig

## Planned Features
* Remap bits/gates for parts with multiple identical units
* Programmatic package footprint generation
* Definition of board edges & filled zones in Zig code
* Board component placement in Zig code
* Export to KiCAD/pcbnew board file

## Stretch Goals / Brainstorm Area
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
