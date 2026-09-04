

import "phoenix_html"
import LiveCharts from "live_charts"

import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}
Hooks.AutoSave = {
  mounted() {
    this.handleBeforeUnload = () => {
      this.pushEvent("auto_save_on_leave", {})
    }
    window.addEventListener("beforeunload", this.handleBeforeUnload)
  },
  destroyed() {
    window.removeEventListener("beforeunload", this.handleBeforeUnload)
  }
}

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

let Uploaders = {
  S3(entries, onViewError) {
    entries.forEach(entry => {
      let xhr = new XMLHttpRequest()
      onViewError(() => xhr.abort())

      xhr.onload = () => (xhr.status >= 200 && xhr.status < 300 ? entry.progress(100) : entry.error())
      xhr.onerror = () => entry.error()

      xhr.upload.addEventListener("progress", event => {
        if (event.lengthComputable) {
          let percent = Math.round((event.loaded / event.total) * 100)
          if (percent < 100) { entry.progress(percent) }
        }
      })

      let url = entry.meta.url
      xhr.open("PUT", url, true)
      xhr.send(entry.file)
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  uploaders: Uploaders,
hooks: {
  ...LiveCharts.Hooks,
  ...Hooks
}
}
)

topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

liveSocket.connect()

window.liveSocket = liveSocket

if ("serviceWorker" in navigator && window.location.hostname !== "localhost") {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/sw.js").catch(err => {
      console.warn("Service worker registration failed:", err)
    })
  })
}

