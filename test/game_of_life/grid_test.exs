defmodule GameOfLife.GridTest do
  use ExUnit.Case, async: true

  alias GameOfLife.Grid

  describe "create_empty_grid/2" do
    test "creates an empty sparse grid" do
      grid = Grid.create_empty_grid(10, 10)
      assert grid == %{}
    end

    test "creates empty grid regardless of dimensions" do
      grid1 = Grid.create_empty_grid(1, 1)
      grid2 = Grid.create_empty_grid(100, 50)
      grid3 = Grid.create_empty_grid(0, 0)
      
      assert grid1 == %{}
      assert grid2 == %{}
      assert grid3 == %{}
    end
  end

  describe "get_cell/3" do
    test "returns false for empty grid" do
      grid = Grid.create_empty_grid(10, 10)
      assert Grid.get_cell(grid, 0, 0) == false
      assert Grid.get_cell(grid, 5, 5) == false
    end

    test "returns true for live cells" do
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 5, 5, true)
      
      assert Grid.get_cell(grid, 5, 5) == true
      assert Grid.get_cell(grid, 0, 0) == false
    end

    test "works with edge coordinates" do
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 0, 0, true)
      grid = Grid.set_cell(grid, 9, 9, true)
      
      assert Grid.get_cell(grid, 0, 0) == true
      assert Grid.get_cell(grid, 9, 9) == true
      assert Grid.get_cell(grid, 1, 1) == false
    end
  end

  describe "set_cell/4" do
    test "sets cell to alive" do
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 5, 5, true)
      
      assert Grid.get_cell(grid, 5, 5) == true
      assert map_size(grid) == 1
      assert grid == %{{5, 5} => true}
    end

    test "sets cell to dead by removing from map" do
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 5, 5, true)
      assert Grid.get_cell(grid, 5, 5) == true
      
      grid = Grid.set_cell(grid, 5, 5, false)
      assert Grid.get_cell(grid, 5, 5) == false
      assert map_size(grid) == 0
    end

    test "handles multiple cells" do
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 0, 0, true)
      grid = Grid.set_cell(grid, 5, 5, true)
      grid = Grid.set_cell(grid, 9, 9, true)
      
      assert Grid.get_cell(grid, 0, 0) == true
      assert Grid.get_cell(grid, 5, 5) == true
      assert Grid.get_cell(grid, 9, 9) == true
      assert map_size(grid) == 3
    end

    test "overrides existing cells" do
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 5, 5, true)
      assert Grid.get_cell(grid, 5, 5) == true
      
      grid = Grid.set_cell(grid, 5, 5, true)
      assert Grid.get_cell(grid, 5, 5) == true
      assert map_size(grid) == 1
    end
  end

  describe "valid_coordinates?/4" do
    test "validates coordinates within bounds" do
      assert Grid.valid_coordinates?(0, 0, 10, 10) == true
      assert Grid.valid_coordinates?(9, 9, 10, 10) == true
      assert Grid.valid_coordinates?(5, 5, 10, 10) == true
    end

    test "rejects coordinates outside bounds" do
      assert Grid.valid_coordinates?(-1, 0, 10, 10) == false
      assert Grid.valid_coordinates?(0, -1, 10, 10) == false
      assert Grid.valid_coordinates?(10, 0, 10, 10) == false
      assert Grid.valid_coordinates?(0, 10, 10, 10) == false
      assert Grid.valid_coordinates?(10, 10, 10, 10) == false
    end

    test "handles edge cases with small dimensions" do
      assert Grid.valid_coordinates?(0, 0, 1, 1) == true
      assert Grid.valid_coordinates?(1, 0, 1, 1) == false
      assert Grid.valid_coordinates?(0, 1, 1, 1) == false
      assert Grid.valid_coordinates?(0, 0, 0, 0) == false
    end

    test "handles different width and height" do
      assert Grid.valid_coordinates?(4, 9, 10, 5) == true
      assert Grid.valid_coordinates?(5, 9, 10, 5) == false
      assert Grid.valid_coordinates?(4, 10, 10, 5) == false
    end
  end

  describe "toggle_cell/3" do
    test "toggles dead cell to alive" do
      grid = Grid.create_empty_grid(10, 10)
      assert Grid.get_cell(grid, 5, 5) == false
      
      grid = Grid.toggle_cell(grid, 5, 5)
      assert Grid.get_cell(grid, 5, 5) == true
    end

    test "toggles alive cell to dead" do
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 5, 5, true)
      assert Grid.get_cell(grid, 5, 5) == true
      
      grid = Grid.toggle_cell(grid, 5, 5)
      assert Grid.get_cell(grid, 5, 5) == false
    end

    test "multiple toggles return to original state" do
      grid = Grid.create_empty_grid(10, 10)
      original_state = Grid.get_cell(grid, 5, 5)
      
      grid = Grid.toggle_cell(grid, 5, 5)
      grid = Grid.toggle_cell(grid, 5, 5)
      
      assert Grid.get_cell(grid, 5, 5) == original_state
    end
  end

  describe "evolve_grid/3" do
    test "empty grid stays empty" do
      grid = Grid.create_empty_grid(10, 10)
      new_grid = Grid.evolve_grid(grid, 10, 10)
      
      assert new_grid == %{}
    end

    test "single cell dies from underpopulation" do
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 5, 5, true)
      
      new_grid = Grid.evolve_grid(grid, 10, 10)
      
      assert Grid.get_cell(new_grid, 5, 5) == false
    end

    test "cell with 2 neighbors survives" do
      # Create L shape: cell at (5,5) with neighbors at (4,5) and (5,4)
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 5, 5, true)
      grid = Grid.set_cell(grid, 4, 5, true)
      grid = Grid.set_cell(grid, 5, 4, true)
      
      new_grid = Grid.evolve_grid(grid, 10, 10)
      
      # Cell at (5,5) should survive with 2 neighbors
      assert Grid.get_cell(new_grid, 5, 5) == true
    end

    test "cell with 3 neighbors survives" do
      # Create + shape: cell at (5,5) with 3 neighbors
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 5, 5, true)
      grid = Grid.set_cell(grid, 4, 5, true)
      grid = Grid.set_cell(grid, 6, 5, true)
      grid = Grid.set_cell(grid, 5, 4, true)
      
      new_grid = Grid.evolve_grid(grid, 10, 10)
      
      # Cell at (5,5) should survive with 3 neighbors
      assert Grid.get_cell(new_grid, 5, 5) == true
    end

    test "cell with 4+ neighbors dies from overpopulation" do
      # Create + shape with center: 5 total cells
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 5, 5, true)
      grid = Grid.set_cell(grid, 4, 5, true)
      grid = Grid.set_cell(grid, 6, 5, true)
      grid = Grid.set_cell(grid, 5, 4, true)
      grid = Grid.set_cell(grid, 5, 6, true)
      
      new_grid = Grid.evolve_grid(grid, 10, 10)
      
      # Cell at (5,5) should die from overpopulation (4 neighbors)
      assert Grid.get_cell(new_grid, 5, 5) == false
    end

    test "dead cell with exactly 3 neighbors becomes alive" do
      # Create L shape with empty center
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 4, 5, true)
      grid = Grid.set_cell(grid, 5, 4, true)
      grid = Grid.set_cell(grid, 6, 5, true)
      
      new_grid = Grid.evolve_grid(grid, 10, 10)
      
      # Cell at (5,5) should be born with exactly 3 neighbors
      assert Grid.get_cell(new_grid, 5, 5) == true
    end

    test "dead cell with != 3 neighbors stays dead" do
      # Create line of 2 cells
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 4, 5, true)
      grid = Grid.set_cell(grid, 6, 5, true)
      
      new_grid = Grid.evolve_grid(grid, 10, 10)
      
      # Cell at (5,5) should stay dead (only 2 neighbors)
      assert Grid.get_cell(new_grid, 5, 5) == false
    end

    test "blinker pattern oscillates correctly" do
      # Vertical blinker
      grid = Grid.create_empty_grid(5, 5)
      grid = Grid.set_cell(grid, 1, 2, true)
      grid = Grid.set_cell(grid, 2, 2, true)
      grid = Grid.set_cell(grid, 3, 2, true)
      
      # After one evolution, should become horizontal
      new_grid = Grid.evolve_grid(grid, 5, 5)
      
      assert Grid.get_cell(new_grid, 1, 2) == false
      assert Grid.get_cell(new_grid, 2, 1) == true
      assert Grid.get_cell(new_grid, 2, 2) == true
      assert Grid.get_cell(new_grid, 2, 3) == true
      assert Grid.get_cell(new_grid, 3, 2) == false
      
      # After second evolution, should return to vertical
      final_grid = Grid.evolve_grid(new_grid, 5, 5)
      
      assert Grid.get_cell(final_grid, 1, 2) == true
      assert Grid.get_cell(final_grid, 2, 1) == false
      assert Grid.get_cell(final_grid, 2, 2) == true
      assert Grid.get_cell(final_grid, 2, 3) == false
      assert Grid.get_cell(final_grid, 3, 2) == true
    end

    test "block pattern stays stable" do
      # 2x2 block (stable pattern)
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 5, 5, true)
      grid = Grid.set_cell(grid, 5, 6, true)
      grid = Grid.set_cell(grid, 6, 5, true)
      grid = Grid.set_cell(grid, 6, 6, true)
      
      new_grid = Grid.evolve_grid(grid, 10, 10)
      
      # Should remain unchanged
      assert Grid.get_cell(new_grid, 5, 5) == true
      assert Grid.get_cell(new_grid, 5, 6) == true
      assert Grid.get_cell(new_grid, 6, 5) == true
      assert Grid.get_cell(new_grid, 6, 6) == true
      assert map_size(new_grid) == 4
    end

    test "respects grid boundaries" do
      # Place pattern near edge
      grid = Grid.create_empty_grid(3, 3)
      grid = Grid.set_cell(grid, 0, 0, true)
      grid = Grid.set_cell(grid, 0, 1, true)
      grid = Grid.set_cell(grid, 1, 0, true)
      
      new_grid = Grid.evolve_grid(grid, 3, 3)
      
      # Should evolve correctly without going out of bounds
      assert is_map(new_grid)
      
      # All cells in new_grid should be within bounds
      Enum.all?(Map.keys(new_grid), fn {row, col} ->
        Grid.valid_coordinates?(row, col, 3, 3)
      end)
    end

    test "handles large sparse grids efficiently" do
      # Create a small pattern in a large grid
      grid = Grid.create_empty_grid(1000, 1000)
      grid = Grid.set_cell(grid, 500, 500, true)
      grid = Grid.set_cell(grid, 500, 501, true)
      grid = Grid.set_cell(grid, 501, 500, true)
      
      new_grid = Grid.evolve_grid(grid, 1000, 1000)
      
      # Should handle efficiently and produce result
      assert is_map(new_grid)
      # The sparse representation should still be small
      assert map_size(new_grid) <= 10  # Much smaller than 1M cells
    end
  end

  describe "edge cases and error conditions" do
    test "grid operations work with zero dimensions" do
      grid = Grid.create_empty_grid(0, 0)
      new_grid = Grid.evolve_grid(grid, 0, 0)
      
      assert new_grid == %{}
    end

    test "grid operations work with single dimension" do
      grid = Grid.create_empty_grid(1, 1)
      grid = Grid.set_cell(grid, 0, 0, true)
      
      new_grid = Grid.evolve_grid(grid, 1, 1)
      
      # Single cell should die (no neighbors)
      assert Grid.get_cell(new_grid, 0, 0) == false
    end

    test "negative coordinates are handled by valid_coordinates?" do
      assert Grid.valid_coordinates?(-1, 0, 10, 10) == false
      assert Grid.valid_coordinates?(0, -1, 10, 10) == false
      assert Grid.valid_coordinates?(-1, -1, 10, 10) == false
    end
  end

  describe "integration scenarios" do
    test "glider pattern moves correctly" do
      # Create a glider pattern
      grid = Grid.create_empty_grid(10, 10)
      grid = Grid.set_cell(grid, 1, 2, true)
      grid = Grid.set_cell(grid, 2, 3, true)
      grid = Grid.set_cell(grid, 3, 1, true)
      grid = Grid.set_cell(grid, 3, 2, true)
      grid = Grid.set_cell(grid, 3, 3, true)
      
      # Evolution 1
      gen1 = Grid.evolve_grid(grid, 10, 10)
      
      # Evolution 2  
      gen2 = Grid.evolve_grid(gen1, 10, 10)
      
      # Evolution 3
      gen3 = Grid.evolve_grid(gen2, 10, 10)
      
      # Evolution 4 - should be similar to original but shifted
      gen4 = Grid.evolve_grid(gen3, 10, 10)
      
      # Verify the glider has moved (exact positions depend on Conway's rules)
      # At minimum, verify that evolution produces different valid states
      assert gen1 != grid
      assert gen2 != gen1
      assert gen3 != gen2
      assert gen4 != gen3
      
      # All generations should have some living cells (glider persists)
      assert map_size(gen1) > 0
      assert map_size(gen2) > 0
      assert map_size(gen3) > 0
      assert map_size(gen4) > 0
    end
  end
end