defmodule GameOfLife.Grid do
  @moduledoc """
  Core Game of Life logic including grid operations, cell evolution, and Conway's rules implementation.
  Uses sparse grid representation for optimal performance.
  """

  @doc """
  Creates an empty sparse grid.
  In sparse representation, only living cells are stored in the map.
  """
  def create_empty_grid(_width, _height) do
    %{}
  end

  @doc """
  Checks if a cell is alive in the sparse grid.
  In sparse grid, if cell is not in map, it's dead (false).
  """
  def get_cell(grid, row, col) do
    Map.has_key?(grid, {row, col})
  end

  @doc """
  Sets a cell's state in the sparse grid.
  Live cells are stored, dead cells are removed.
  """
  def set_cell(grid, row, col, true) do
    Map.put(grid, {row, col}, true)
  end
  def set_cell(grid, row, col, false) do
    Map.delete(grid, {row, col})
  end

  @doc """
  Validates if coordinates are within the grid boundaries.
  """
  def valid_coordinates?(row, col, width, height) do
    row >= 0 and row < height and col >= 0 and col < width
  end

  @doc """
  Evolves the grid one generation according to Conway's rules.
  Uses optimized approach that only processes cells that could change.
  """
  def evolve_grid(grid, width, height) do
    # Get all cells that need to be checked (live cells + their neighbors)
    cells_to_check = get_cells_to_check(grid, width, height)
    
    # Process only the relevant cells
    Enum.reduce(cells_to_check, %{}, fn {row, col}, new_grid ->
      current_alive = get_cell(grid, row, col)
      neighbor_count = count_live_neighbors(grid, row, col, width, height)
      
      new_state = case {current_alive, neighbor_count} do
        {true, n} when n < 2 -> false    # Dies from underpopulation
        {true, n} when n in [2, 3] -> true    # Survives
        {true, n} when n > 3 -> false    # Dies from overpopulation
        {false, 3} -> true               # Born from reproduction
        {false, _} -> false              # Stays dead
      end
      
      set_cell(new_grid, row, col, new_state)
    end)
  end

  @doc """
  Toggles the state of a cell at the given coordinates.
  """
  def toggle_cell(grid, row, col) do
    current_value = get_cell(grid, row, col)
    set_cell(grid, row, col, not current_value)
  end

  # Private functions

  @doc false
  # Get all cells that could possibly change state
  defp get_cells_to_check(grid, width, height) do
    grid
    |> Map.keys()
    |> Enum.flat_map(fn {row, col} ->
      # For each live cell, include itself and all neighbors
      neighbors = [
        {row - 1, col - 1}, {row - 1, col}, {row - 1, col + 1},
        {row, col - 1}, {row, col}, {row, col + 1},
        {row + 1, col - 1}, {row + 1, col}, {row + 1, col + 1}
      ]
      
      Enum.filter(neighbors, fn {r, c} -> 
        valid_coordinates?(r, c, width, height)
      end)
    end)
    |> Enum.uniq()
  end

  @doc false
  # Optimized neighbor counting using direct map lookups
  defp count_live_neighbors(grid, row, col, width, height) do
    [
      {row - 1, col - 1}, {row - 1, col}, {row - 1, col + 1},
      {row, col - 1},                       {row, col + 1},
      {row + 1, col - 1}, {row + 1, col}, {row + 1, col + 1}
    ]
    |> Enum.count(fn {r, c} ->
      valid_coordinates?(r, c, width, height) and Map.has_key?(grid, {r, c})
    end)
  end
end