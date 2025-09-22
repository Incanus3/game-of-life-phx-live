// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Game Canvas Hook for high-performance rendering
const GameCanvas = {
  mounted() {
    this.canvas = this.el
    this.ctx = this.canvas.getContext('2d')
    this.cellSize = 12
    this.gridWidth = parseInt(this.el.dataset.width)
    this.gridHeight = parseInt(this.el.dataset.height)
    
    // Set up click handling for cell toggling
    this.canvas.addEventListener('click', (e) => {
      const rect = this.canvas.getBoundingClientRect()
      const x = e.clientX - rect.left
      const y = e.clientY - rect.top
      
      const col = Math.floor(x / this.cellSize)
      const row = Math.floor(y / this.cellSize)
      
      if (col >= 0 && col < this.gridWidth && row >= 0 && row < this.gridHeight) {
        this.pushEvent('toggle_cell', { row: row, col: col })
      }
    })
    
    // Initial render
    this.render()
  },
  
  updated() {
    this.render()
  },
  
  render() {
    const grid = JSON.parse(this.el.dataset.grid || '{}')
    const ctx = this.ctx
    
    // Clear canvas
    ctx.fillStyle = '#2a2a2a' // Dark background
    ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)
    
    // Draw grid lines (optional - can be removed for better performance)
    ctx.strokeStyle = '#3a3a3a'
    ctx.lineWidth = 1
    
    // Vertical lines
    for (let i = 0; i <= this.gridWidth; i++) {
      ctx.beginPath()
      ctx.moveTo(i * this.cellSize, 0)
      ctx.lineTo(i * this.cellSize, this.canvas.height)
      ctx.stroke()
    }
    
    // Horizontal lines
    for (let i = 0; i <= this.gridHeight; i++) {
      ctx.beginPath()
      ctx.moveTo(0, i * this.cellSize)
      ctx.lineTo(this.canvas.width, i * this.cellSize)
      ctx.stroke()
    }
    
    // Draw live cells
    ctx.fillStyle = '#4ade80' // Green for live cells
    Object.keys(grid).forEach(key => {
      if (grid[key]) {
        const [row, col] = key.split(',').map(Number)
        ctx.fillRect(
          col * this.cellSize + 1,
          row * this.cellSize + 1,
          this.cellSize - 2,
          this.cellSize - 2
        )
      }
    })
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {GameCanvas},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

