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
    pattern = socket.assigns.patterns.patterns[pattern_name]
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
      <%= render_header(assigns) %>
      <%= render_controls(assigns) %>
      <%= render_game_canvas(assigns) %>
      <%= render_instructions(assigns) %>
    </div>
    """
  end
  
  # Private render functions for better maintainability
  
  defp render_header(assigns) do
    ~H"""
    <div class="header">
      <h1>Conway's Game of Life</h1>
      <div class="stats">
        <span>Generation: <%= @game_state.generation %></span>
        <span>Status: <%= if @game_state.playing, do: "Playing", else: "Paused" %></span>
      </div>
    </div>
    """
  end
  
  defp render_controls(assigns) do
    ~H"""
    <div class="controls">
      <%= render_game_controls(assigns) %>
      <%= render_speed_control(assigns) %>
      <%= render_pattern_control(assigns) %>
    </div>
    """
  end
  
  defp render_game_controls(assigns) do
    ~H"""
    <div class="control-group">
      <button
        phx-click={if @game_state.playing, do: "pause", else: "play"}
        class={["btn", if(@game_state.playing, do: "btn-pause", else: "btn-play")]}
      >
        <%= if @game_state.playing, do: "⏸ Pause", else: "▶ Play" %>
      </button>
      <button phx-click="reset" class="btn btn-reset">🔄 Reset</button>
    </div>
    """
  end
  
  defp render_speed_control(assigns) do
    ~H"""
    <div class="control-group">
      <form phx-change="speed_change">
        <label for="speed">Speed:</label>
        <input
          type="range"
          id="speed"
          name="speed"
          min="50"
          max="1000"
          step="50"
          value={@game_state.speed}
        />
      </form>
      <span><%= @game_state.speed %>ms</span>
    </div>
    """
  end
  
  defp render_pattern_control(assigns) do
    ~H"""
    <div class="control-group">
      <form phx-change="pattern_change">
        <label for="pattern">Pattern:</label>
        <select id="pattern" name="pattern">
          <%= for {category_name, patterns} <- @patterns.categories do %>
            <optgroup label={category_name}>
              <%= for {pattern_key, pattern_name, tooltip} <- patterns do %>
                <%= if pattern_key == @selected_pattern do %>
                  <option value={pattern_key} selected title={tooltip}>
                    <%= pattern_name %>
                  </option>
                <% else %>
                  <option value={pattern_key} title={tooltip}>
                    <%= pattern_name %>
                  </option>
                <% end %>
              <% end %>
            </optgroup>
          <% end %>
        </select>
      </form>
      <button phx-click="load_pattern" class="btn btn-load">Load Pattern</button>
    </div>
    """
  end
  
  defp render_game_canvas(assigns) do
    ~H"""
    <canvas
      id="game-canvas"
      width={@game_state.width * 12}
      height={@game_state.height * 12}
      phx-hook="GameCanvas"
      phx-update="ignore"
      data-width={@game_state.width}
      data-height={@game_state.height}
      data-grid={Jason.encode!(grid_to_json(@game_state.grid))}
      data-generation={@game_state.generation}
      class="game-canvas"
    >
      Your browser doesn't support HTML5 Canvas.
    </canvas>
    """
  end
  
  defp render_instructions(assigns) do
    ~H"""
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
    """
  end
  
  # Helper function to convert grid with tuple keys to JSON-encodable format
  defp grid_to_json(grid) do
    for {{row, col}, _value} <- grid, into: %{} do
      {"#{row},#{col}", true}
    end
  end
end
