defmodule GameOfLife.Game do
  use GenServer
  require Logger

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def play() do
    GenServer.cast(__MODULE__, :play)
  end

  def pause() do
    GenServer.cast(__MODULE__, :pause)
  end

  def reset() do
    GenServer.cast(__MODULE__, :reset)
  end

  def toggle_cell(row, col) do
    GenServer.cast(__MODULE__, {:toggle_cell, row, col})
  end

  def set_speed(speed) when speed > 0 do
    GenServer.cast(__MODULE__, {:set_speed, speed})
  end

  def load_pattern(pattern) do
    GenServer.cast(__MODULE__, {:load_pattern, pattern})
  end

  # Server callbacks

  @impl true
  def init(opts) do
    width = Keyword.get(opts, :width, 100)
    height = Keyword.get(opts, :height, 60)
    speed = Keyword.get(opts, :speed, 200)

    state = %{
      grid: create_empty_grid(width, height),
      width: width,
      height: height,
      generation: 0,
      playing: false,
      speed: speed,
      timer_ref: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:play, state) do
    if not state.playing do
      timer_ref = schedule_next_generation(state.speed)
      new_state = %{state | playing: true, timer_ref: timer_ref}
      broadcast_state_change(new_state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast(:pause, state) do
    if state.playing do
      if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
      new_state = %{state | playing: false, timer_ref: nil}
      broadcast_state_change(new_state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast(:reset, state) do
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
    
    new_state = %{
      state
      | grid: create_empty_grid(state.width, state.height),
        generation: 0,
        playing: false,
        timer_ref: nil
    }
    
    broadcast_state_change(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:toggle_cell, row, col}, state) do
    if valid_coordinates?(row, col, state.width, state.height) do
      current_value = get_cell(state.grid, row, col)
      new_grid = set_cell(state.grid, row, col, not current_value)
      new_state = %{state | grid: new_grid}
      broadcast_state_change(new_state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:set_speed, speed}, state) do
    new_state = %{state | speed: speed}
    
    # If currently playing, restart timer with new speed
    new_state = if state.playing do
      if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
      timer_ref = schedule_next_generation(speed)
      %{new_state | timer_ref: timer_ref}
    else
      new_state
    end
    
    broadcast_state_change(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:load_pattern, pattern}, state) do
    new_grid = load_pattern_onto_grid(pattern, state.grid, state.width, state.height)
    new_state = %{state | grid: new_grid, generation: 0}
    broadcast_state_change(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:next_generation, state) do
    if state.playing do
      new_grid = evolve_grid(state.grid, state.width, state.height)
      new_generation = state.generation + 1
      timer_ref = schedule_next_generation(state.speed)
      
      new_state = %{
        state
        | grid: new_grid,
          generation: new_generation,
          timer_ref: timer_ref
      }
      
      broadcast_state_change(new_state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  # Private functions

  defp create_empty_grid(width, height) do
    for row <- 0..(height - 1), col <- 0..(width - 1), into: %{} do
      {{row, col}, false}
    end
  end

  defp get_cell(grid, row, col) do
    Map.get(grid, {row, col}, false)
  end

  defp set_cell(grid, row, col, value) do
    Map.put(grid, {row, col}, value)
  end

  defp valid_coordinates?(row, col, width, height) do
    row >= 0 and row < height and col >= 0 and col < width
  end

  defp evolve_grid(grid, width, height) do
    for row <- 0..(height - 1), col <- 0..(width - 1), into: %{} do
      current_alive = get_cell(grid, row, col)
      neighbor_count = count_live_neighbors(grid, row, col, width, height)
      
      new_state = case {current_alive, neighbor_count} do
        {true, n} when n < 2 -> false    # Dies from underpopulation
        {true, n} when n in [2, 3] -> true    # Survives
        {true, n} when n > 3 -> false    # Dies from overpopulation
        {false, 3} -> true               # Born from reproduction
        {false, _} -> false              # Stays dead
      end
      
      {{row, col}, new_state}
    end
  end

  defp count_live_neighbors(grid, row, col, width, height) do
    neighbors = [
      {row - 1, col - 1}, {row - 1, col}, {row - 1, col + 1},
      {row, col - 1},                       {row, col + 1},
      {row + 1, col - 1}, {row + 1, col}, {row + 1, col + 1}
    ]
    
    neighbors
    |> Enum.filter(fn {r, c} -> valid_coordinates?(r, c, width, height) end)
    |> Enum.count(fn {r, c} -> get_cell(grid, r, c) end)
  end

  defp schedule_next_generation(speed) do
    Process.send_after(self(), :next_generation, speed)
  end

  defp broadcast_state_change(state) do
    Phoenix.PubSub.broadcast(GameOfLife.PubSub, "game_state", {:state_change, state})
  end

  # Pattern loading functions
  
  defp load_pattern_onto_grid(pattern, _grid, width, height) do
    # Clear the grid first
    empty_grid = create_empty_grid(width, height)
    
    # Calculate starting position to center the pattern
    pattern_height = length(pattern)
    pattern_width = if pattern_height > 0, do: length(hd(pattern)), else: 0
    
    start_row = div(height - pattern_height, 2)
    start_col = div(width - pattern_width, 2)
    
    # Place the pattern
    pattern
    |> Enum.with_index()
    |> Enum.reduce(empty_grid, fn {row_pattern, row_idx}, acc_grid ->
      row_pattern
      |> Enum.with_index()
      |> Enum.reduce(acc_grid, fn {cell, col_idx}, inner_grid ->
        actual_row = start_row + row_idx
        actual_col = start_col + col_idx
        
        if valid_coordinates?(actual_row, actual_col, width, height) do
          set_cell(inner_grid, actual_row, actual_col, cell)
        else
          inner_grid
        end
      end)
    end)
  end

  # Game of Life patterns with categories and descriptions
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
        [false, false, false, false, false, false, false, false, false, false, false, false, false],
        [true, false, false, false, false, true, false, true, false, false, false, false, true],
        [true, false, false, false, false, true, false, true, false, false, false, false, true],
        [true, false, false, false, false, true, false, true, false, false, false, false, true],
        [false, false, true, true, true, false, false, false, true, true, true, false, false],
        [false, false, false, false, false, false, false, false, false, false, false, false, false],
        [false, false, true, true, true, false, false, false, true, true, true, false, false],
        [true, false, false, false, false, true, false, true, false, false, false, false, true],
        [true, false, false, false, false, true, false, true, false, false, false, false, true],
        [true, false, false, false, false, true, false, true, false, false, false, false, true],
        [false, false, false, false, false, false, false, false, false, false, false, false, false],
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
        [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, true, false, false, false, false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false, false, false, false, false, true, true, false, false, false, false, false, false, true, true, false, false, false, false, false, false, false, false, false, false, false, false, true, true],
        [false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false, true, true, false, false, false, false, false, false, false, false, false, false, false, false, true, true],
        [true, true, false, false, false, false, false, false, false, false, true, false, false, false, false, false, true, false, false, false, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
        [true, true, false, false, false, false, false, false, false, false, true, false, false, false, true, false, true, true, false, false, false, false, true, false, true, false, false, false, false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false, false, false, true, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false, false, false, false, false, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
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
        {"Basic Patterns", [
          {"glider", "Glider", "Classic diagonal spaceship that moves across the grid"},
          {"block", "Block", "Simple 2×2 still life that never changes"},
          {"blinker", "Blinker", "Simple period-2 oscillator (3 cells in a line)"}
        ]},
        {"Oscillators", [
          {"toad", "Toad", "Period-2 oscillator that rocks back and forth"},
          {"beacon", "Beacon", "Period-2 oscillator with flashing corner"},
          {"pulsar", "Pulsar", "Beautiful period-3 oscillator (13×13)"},
          {"pentadecathlon", "Pentadecathlon", "Period-15 oscillator (10×3)"}
        ]},
        {"Spaceships", [
          {"lightweight_spaceship", "Lightweight Spaceship", "Travels horizontally every 4 generations"},
          {"middleweight_spaceship", "Middleweight Spaceship", "Larger, faster spaceship"}
        ]},
        {"Glider Guns", [
          {"gosper_glider_gun", "Gosper Glider Gun", "Continuously creates gliders! (36×9)"}
        ]},
        {"Methuselahs", [
          {"r_pentomino", "R-Pentomino", "Evolves for 1,103 generations before stabilizing"},
          {"diehard", "Diehard", "Lives for exactly 130 generations then dies completely"},
          {"acorn", "Acorn", "Takes 5,206 generations to stabilize (amazing!)"}
        ]},
        {"Still Lifes", [
          {"beehive", "Beehive", "Hexagonal stable pattern"},
          {"loaf", "Loaf", "Asymmetric stable pattern with a 'bite' taken out"},
          {"boat", "Boat", "Small 3×3 stable pattern"}
        ]}
      ]
    }
  end
end