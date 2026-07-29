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

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
import LiveCharts from "live_charts"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"


// AutoSave hook for workout changes
let Hooks = {}
Hooks.AutoSave = {
  mounted() {
    // Save on page navigation/beforeunload
    this.handleBeforeUnload = () => {
      this.pushEvent("auto_save_on_leave", {})
    }
    window.addEventListener("beforeunload", this.handleBeforeUnload)
  },
  destroyed() {
    window.removeEventListener("beforeunload", this.handleBeforeUnload)
  }
}

// Copies the value in data-clipboard-text and briefly swaps the button label.
// navigator.clipboard needs a secure context, so fall back to a temporary
// textarea + execCommand when serving plain http over LAN.
Hooks.Copy = {
  mounted() {
    this.el.addEventListener("click", () => {
      const text = this.el.dataset.clipboardText
      const done = () => {
        const label = this.el.querySelector("[data-copy-label]")
        if (!label) return
        const original = label.textContent
        label.textContent = "Copied"
        clearTimeout(this.timer)
        this.timer = setTimeout(() => { label.textContent = original }, 1600)
      }

      if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(text).then(done)
      } else {
        const ta = document.createElement("textarea")
        ta.value = text
        ta.style.position = "fixed"
        ta.style.opacity = "0"
        document.body.appendChild(ta)
        ta.select()
        try { document.execCommand("copy"); done() } finally { ta.remove() }
      }
    })
  },
  destroyed() {
    clearTimeout(this.timer)
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
hooks: {
  ...LiveCharts.Hooks,
  ...Hooks
}
}
)

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

