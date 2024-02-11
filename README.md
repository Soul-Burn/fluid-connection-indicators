# Features

Shows indicators on fluid connections, inserters, and mining drills.

## Fluid connections

### Lightweight mode (default)

![](https://raw.githubusercontent.com/Soul-Burn/fluid-connection-indicators/work/.external/lite.png)

Less cluttered. Only shows indicators when attention is required.

* Blue - Pipe is connected, or this fluid is connected in another pipe
* Yellow - Pipe connection is blocked by another entity, or this fluid is not connected
* Red - Pipe connection is blocked by an entity with fluid connections e.g. pipe to ground. Also when entities with different fluid filters are connected.

When a fluid is connected in another pipe, the indication level goes down.

### Full mode (old default)

![](https://raw.githubusercontent.com/Soul-Burn/fluid-connection-indicators/work/.external/full.png)

More colorful. Shows indicators also on active and unnecessary connections.

* Green - Pipe is connected
* Blue - Pipe is not connected
* Gray - Pipe is not connected but this fluid is connected in another pipe
* Yellow - Pipe connection is blocked by another entity
* Red - Pipe connection is blocked by an entity with fluid connections e.g. pipe to ground. Also when entities with different fluid filters are connected.

When a fluid is connected in another pipe, the indication level goes down.

## Inserters and mining drills

* Red - When pickup or drop position is obstructed or an open space not served by an inserter/drill
* Yellow/nothing - Connected to a relevant entity or an open space served by another inserter/drill

# Settings

* Enable indicators on fluid connection entities
  * Off - Disabled
  * Lite - Only show indicators on issues
  * Full - Shows indicators in more cases
* Enable indicators on inserters and mining drills
