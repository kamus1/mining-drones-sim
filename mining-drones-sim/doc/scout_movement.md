The drone scout uses a simple stochastic exploration algorithm in the `_explore_step()` function:

1. **Current Cell Processing**:
   - Checks the current cell's state
   - If it contains gold (`Cell.GOLD`), prints an "ORE FOUND" message
   - If it's not an obstacle, marks it as explored (`Cell.EXPLORED`)

2. **Neighbor Selection**:
   - Considers adjacent cells in 4 directions (or 8 if diagonals are allowed)
   - Filters out cells that are out of bounds or are obstacles
   - Creates a list of valid candidate cells

3. **Decision Making**:
   - Sorts candidates by cell state in ascending order: UNKNOWN (0) → EXPLORED (1) → GOLD (2)
   - This prioritizes unexplored areas while allowing some randomness
   - Randomly selects one candidate from the sorted list

4. **Movement**:
   - Updates its position to the selected cell
   - Repeats the process on each timer tick

This creates a random walk behavior that prefers exploring unknown territory but can occasionally revisit explored areas or approach known gold deposits. The algorithm is simple and efficient for basic map exploration without complex pathfinding.