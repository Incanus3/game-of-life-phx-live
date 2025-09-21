defmodule GameOfLifeWeb.GameLive do
  use GameOfLifeWeb, :live_view
  alias GameOfLife.Game

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(GameOfLife.PubSub, "game_state")
    end

    game_state = Game.get_state()
    patterns = Game.get_patterns()

    socket =
      socket
      |> assign(:game_state, game_state)
      |> assign(:patterns, patterns)
      |> assign(:selected_pattern, "glider")

    {:ok, socket}
  end

  @impl true
  def handle_event("play", _params, socket) do
    Game.play()
    {:noreply, socket}
  end

  @impl true
  def handle_event("pause", _params, socket) do
    Game.pause()
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    Game.reset()
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_cell", %{"row" => row, "col" => col}, socket) do
    Game.toggle_cell(String.to_integer(row), String.to_integer(col))
    {:noreply, socket}
  end

  @impl true
  def handle_event("speed_change", %{"speed" => speed}, socket) do
    speed_value = String.to_integer(speed)
    Game.set_speed(speed_value)
    {:noreply, socket}
  end

  @impl true
  def handle_event("pattern_change", %{"pattern" => pattern_name}, socket) do
    {:noreply, assign(socket, :selected_pattern, pattern_name)}
  end

  @impl true
  def handle_event("load_pattern", _params, socket) do
    pattern_name = socket.assigns.selected_pattern
    pattern = socket.assigns.patterns[pattern_name]
    if pattern, do: Game.load_pattern(pattern)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:state_change, new_state}, socket) do
    {:noreply, assign(socket, :game_state, new_state)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="game-of-life-container">
      <div class="header">
        <h1>Conway's Game of Life</h1>
        <div class="stats">
          <span>Generation: <%= @game_state.generation %></span>
          <span>Status: <%= if @game_state.playing, do: "Playing", else: "Paused" %></span>
        </div>
      </div>

      <div class="controls">
        <div class="control-group">
          <button
            phx-click={if @game_state.playing, do: "pause", else: "play"}
            class={["btn", if(@game_state.playing, do: "btn-pause", else: "btn-play")]}
          >
            <%= if @game_state.playing, do: "⏸ Pause", else: "▶ Play" %>
          </button>
          <button phx-click="reset" class="btn btn-reset">🔄 Reset</button>
        </div>

        <div class="control-group">
          <label for="speed">Speed:</label>
          <input
            type="range"
            id="speed"
            name="speed"
            min="50"
            max="1000"
            step="50"
            value={@game_state.speed}
            phx-change="speed_change"
          />
          <span><%= @game_state.speed %>ms</span>
        </div>

        <div class="control-group">
          <form phx-change="pattern_change">
            <label for="pattern">Pattern:</label>
            <select id="pattern" name="pattern">
              <%= for {pattern_name, _} <- @patterns do %>
                <%= if pattern_name == @selected_pattern do %>
                  <option value={pattern_name} selected>
                    <%= String.capitalize(pattern_name) %>
                  </option>
                <% else %>
                  <option value={pattern_name}>
                    <%= String.capitalize(pattern_name) %>
                  </option>
                <% end %>
              <% end %>
            </select>
          </form>
          <button phx-click="load_pattern" class="btn btn-load">Load Pattern</button>
        </div>
      </div>

      <div class="game-grid" style={"grid-template-columns: repeat(#{@game_state.width}, 1fr);"}>
        <%= for row <- 0..(@game_state.height - 1) do %>
          <%= for col <- 0..(@game_state.width - 1) do %>
            <div
              class={["cell", if(get_cell_state(@game_state.grid, row, col), do: "alive", else: "dead")]}
              phx-click="toggle_cell"
              phx-value-row={row}
              phx-value-col={col}
            >
            </div>
          <% end %>
        <% end %>
      </div>

      <div class="instructions">
        <h3>Instructions:</h3>
        <ul>
          <li>Click on cells to toggle them alive/dead</li>
          <li>Use Play/Pause to control the simulation</li>
          <li>Adjust speed with the slider</li>
          <li>Load predefined patterns to see interesting behaviors</li>
        </ul>
        <h4>Rules of Conway's Game of Life:</h4>
        <ol>
          <li>Any live cell with fewer than two live neighbors dies (underpopulation)</li>
          <li>Any live cell with two or three live neighbors survives</li>
          <li>Any live cell with more than three live neighbors dies (overpopulation)</li>
          <li>Any dead cell with exactly three live neighbors becomes alive (reproduction)</li>
        </ol>
      </div>
    </div>
    """
  end

  # Helper function to get cell state from the grid
  defp get_cell_state(grid, row, col) do
    Map.get(grid, {row, col}, false)
  end
end