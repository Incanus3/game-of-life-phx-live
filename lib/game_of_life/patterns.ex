defmodule GameOfLife.Patterns do
  @moduledoc """
  Manages Game of Life patterns including definitions, categories, and pattern loading operations.
  """

  @doc """
  Returns all available patterns with their data and categorization.
  """
  def get_patterns() do
    %{
      # Pattern data (pattern_name => grid)
      patterns: %{
        # Basic patterns
        "glider" => [
          [false, true, false],
          [false, false, true],
          [true, true, true]
        ],
        "block" => [
          [true, true],
          [true, true]
        ],
        "blinker" => [
          [true, true, true]
        ],

        # Period 2 oscillators
        "toad" => [
          [false, true, true, true],
          [true, true, true, false]
        ],
        "beacon" => [
          [true, true, false, false],
          [true, true, false, false],
          [false, false, true, true],
          [false, false, true, true]
        ],

        # Spaceships
        "lightweight_spaceship" => [
          [false, true, false, false, true],
          [true, false, false, false, false],
          [true, false, false, false, true],
          [true, true, true, true, false]
        ],
        "middleweight_spaceship" => [
          [false, false, true, false, false, false],
          [false, true, false, false, false, true],
          [true, false, false, false, false, false],
          [true, false, false, false, false, true],
          [true, true, true, true, true, false]
        ],

        # Oscillators
        "pulsar" => [
          [false, false, true, true, true, false, false, false, true, true, true, false, false],
          [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
          [true, false, false, false, false, true, false, true, false, false, false, false, true],
          [true, false, false, false, false, true, false, true, false, false, false, false, true],
          [true, false, false, false, false, true, false, true, false, false, false, false, true],
          [false, false, true, true, true, false, false, false, true, true, true, false, false],
          [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
          [false, false, true, true, true, false, false, false, true, true, true, false, false],
          [true, false, false, false, false, true, false, true, false, false, false, false, true],
          [true, false, false, false, false, true, false, true, false, false, false, false, true],
          [true, false, false, false, false, true, false, true, false, false, false, false, true],
          [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
          [false, false, true, true, true, false, false, false, true, true, true, false, false]
        ],

        # Interesting patterns
        "pentadecathlon" => [
          [false, false, true, false, false, false, false, true, false, false],
          [true, true, false, true, true, true, true, false, true, true],
          [false, false, true, false, false, false, false, true, false, false]
        ],
        "r_pentomino" => [
          [false, true, true],
          [true, true, false],
          [false, true, false]
        ],

        # Glider gun (classic pattern that generates gliders)
        "gosper_glider_gun" => [
          [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
          [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
          [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true
          ],
          [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true
          ],
          [
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
          [
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            true,
            false,
            true,
            true,
            false,
            false,
            false,
            false,
            true,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
          [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
          [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
          [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ]
        ],

        # Methuselah patterns (evolve for a long time)
        "diehard" => [
          [false, false, false, false, false, false, true, false],
          [true, true, false, false, false, false, false, false],
          [false, true, false, false, false, true, true, true]
        ],
        "acorn" => [
          [false, true, false, false, false, false, false],
          [false, false, false, true, false, false, false],
          [true, true, false, false, true, true, true]
        ],

        # Still lifes
        "beehive" => [
          [false, true, true, false],
          [true, false, false, true],
          [false, true, true, false]
        ],
        "loaf" => [
          [false, true, true, false],
          [true, false, false, true],
          [false, true, false, true],
          [false, false, true, false]
        ],
        "boat" => [
          [true, true, false],
          [true, false, true],
          [false, true, false]
        ]
      },
      # Pattern categories with names and tooltips
      categories: [
        {"Basic Patterns",
         [
           {"glider", "Glider", "Classic diagonal spaceship that moves across the grid"},
           {"block", "Block", "Simple 2×2 still life that never changes"},
           {"blinker", "Blinker", "Simple period-2 oscillator (3 cells in a line)"}
         ]},
        {"Oscillators",
         [
           {"toad", "Toad", "Period-2 oscillator that rocks back and forth"},
           {"beacon", "Beacon", "Period-2 oscillator with flashing corner"},
           {"pulsar", "Pulsar", "Beautiful period-3 oscillator (13×13)"},
           {"pentadecathlon", "Pentadecathlon", "Period-15 oscillator (10×3)"}
         ]},
        {"Spaceships",
         [
           {"lightweight_spaceship", "Lightweight Spaceship",
            "Travels horizontally every 4 generations"},
           {"middleweight_spaceship", "Middleweight Spaceship", "Larger, faster spaceship"}
         ]},
        {"Glider Guns",
         [
           {"gosper_glider_gun", "Gosper Glider Gun", "Continuously creates gliders! (36×9)"}
         ]},
        {"Methuselahs",
         [
           {"r_pentomino", "R-Pentomino", "Evolves for 1,103 generations before stabilizing"},
           {"diehard", "Diehard", "Lives for exactly 130 generations then dies completely"},
           {"acorn", "Acorn", "Takes 5,206 generations to stabilize (amazing!)"}
         ]},
        {"Still Lifes",
         [
           {"beehive", "Beehive", "Hexagonal stable pattern"},
           {"loaf", "Loaf", "Asymmetric stable pattern with a 'bite' taken out"},
           {"boat", "Boat", "Small 3×3 stable pattern"}
         ]}
      ]
    }
  end

  @doc """
  Loads a pattern onto a grid, centering it automatically.
  Returns a new sparse grid containing only the live cells from the pattern.
  """
  def load_pattern_onto_grid(pattern, _grid, width, height) do
    # Start with empty grid (sparse representation)
    empty_grid = %{}

    # Calculate starting position to center the pattern
    pattern_height = length(pattern)
    pattern_width = if pattern_height > 0, do: length(hd(pattern)), else: 0

    start_row = div(height - pattern_height, 2)
    start_col = div(width - pattern_width, 2)

    # Place only the live cells from the pattern
    pattern
    |> Enum.with_index()
    |> Enum.reduce(empty_grid, fn {row_pattern, row_idx}, acc_grid ->
      row_pattern
      |> Enum.with_index()
      |> Enum.reduce(acc_grid, fn {cell, col_idx}, inner_grid ->
        actual_row = start_row + row_idx
        actual_col = start_col + col_idx

        if valid_coordinates?(actual_row, actual_col, width, height) and cell do
          Map.put(inner_grid, {actual_row, actual_col}, true)
        else
          inner_grid
        end
      end)
    end)
  end

  # Private helper function
  defp valid_coordinates?(row, col, width, height) do
    row >= 0 and row < height and col >= 0 and col < width
  end
end
