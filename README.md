# Features

Shows indicators on fluid connections, inserters, and mining drills.

For fluid connections:

* Green - Pipe is connected
* Blue - Pipe is not connected
* Gray - Pipe is not connected but this fluid is connected in another pipe
* Yellow - Pipe connection is blocked by another entity
* Red - Pipe connection is blocked by an entity with fluid connections e.g. pipe to ground. Also when entities with different fluid filters are connected.

When a fluid is connected in another pipe, the indication level goes down.

For inserters:

* Red - When pickup or drop position is obstructed, or open space not served by another inserter.
* Yellow - Normal behavior.

For inserters and mining drills:

* Red - When pickup or drop position is obstructed or an open space not served by an inserter/drill
* Yellow/nothing - Connected to a relevant entity or an open space served by another inserter/drill
