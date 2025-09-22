defmodule GameOfLife.Game do
  @moduledoc """
  GenServer implementation for Game of Life that coordinates between 
  the Grid (core logic) and Patterns (pattern management) modules.
  """

  use GenServer
  require Logger

  alias GameOfLife.{Grid, Patterns}

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

  def get_patterns() do
    Patterns.get_patterns()
  end

  # Server callbacks

  @impl true
  def init(opts) do
    width = Keyword.get(opts, :width, 100)
    height = Keyword.get(opts, :height, 60)
    speed = Keyword.get(opts, :speed, 200)

    state = %{
      grid: Grid.create_empty_grid(width, height),
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
      | grid: Grid.create_empty_grid(state.width, state.height),
        generation: 0,
        playing: false,
        timer_ref: nil
    }

    broadcast_state_change(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:toggle_cell, row, col}, state) do
    if Grid.valid_coordinates?(row, col, state.width, state.height) do
      new_grid = Grid.toggle_cell(state.grid, row, col)
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
    new_state =
      if state.playing do
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
    new_grid = Patterns.load_pattern_onto_grid(pattern, state.grid, state.width, state.height)
    new_state = %{state | grid: new_grid, generation: 0}
    broadcast_state_change(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:next_generation, state) do
    if state.playing do
      new_grid = Grid.evolve_grid(state.grid, state.width, state.height)
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

  # Private functions for GenServer coordination

  defp schedule_next_generation(speed) do
    Process.send_after(self(), :next_generation, speed)
  end

  defp broadcast_state_change(state) do
    Phoenix.PubSub.broadcast(GameOfLife.PubSub, "game_state", {:state_change, state})
  end
end
