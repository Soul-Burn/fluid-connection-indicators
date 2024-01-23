# Features

Shows indicators on fluid connections:

* Green - Pipe is connected
* Blue - Pipe is not connected
* Gray - Pipe is not connected but this fluid is connected in another pipe
* Yellow - Pipe connection is blocked by another entity
* Red - Pipe connection is blocked by an entity with fluid connections e.g. pipe to ground. Also when entities with different fluid filters are connected.

When a fluid is connected in another pipe, the indication level goes down.

# Known issues

* Indicators do not update when a recipe is changed. Rotating the entity or rebuilding it would update the indicators.
