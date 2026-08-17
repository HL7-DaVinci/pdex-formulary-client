// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Bootstrap is loaded globally from vendor/assets (bundle includes Popper)
function initializeTooltips() {
  document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach((element) => {
    window.bootstrap.Tooltip.getOrCreateInstance(element)
  })
}

// The compare search can take a while; animate an estimated progress bar
// based on the formulary drug count shown on the page.
function initializeCompareProgress() {
  const trigger = document.getElementById("compare-url")
  if (!trigger) return

  trigger.addEventListener("click", () => {
    const container = document.getElementById("compare-progress-bar-container")
    if (!container || container.classList.contains("show")) return
    container.classList.add("show")

    const bar = container.querySelector(".compare-progress-bar")
    const counter = document.querySelector(".client-connected")
    const match = counter ? counter.textContent.match(/(\d+)(?!.*\d)/) : null
    const drugCount = match ? parseFloat(match[0]) : 100
    let percent = 0.0

    const update = setInterval(() => {
      if (percent > 99.5 || !bar) {
        clearInterval(update)
        return
      }
      percent += 400.0 / drugCount
      bar.setAttribute("aria-valuenow", percent.toFixed(2))
      bar.style.width = percent.toFixed(2) + "%"
      bar.textContent = percent.toFixed(2) + "%"
    }, 25)
  })
}

// Replace raw ndjson preview sources with collapsible trees (json-formatter-js,
// loaded globally from vendor/assets). Entries that fail to parse stay as text.
function renderNdjsonPreviews(frame) {
  if (!window.JSONFormatter) return

  frame.querySelectorAll(".ndjson-entry").forEach((entry) => {
    const source = entry.querySelector(".ndjson-source")
    if (!source) return

    let parsed
    try {
      parsed = JSON.parse(source.textContent)
    } catch {
      return
    }
    const formatter = new JSONFormatter(parsed, 1, { theme: "dark" })
    entry.replaceChildren(formatter.render())
  })
}

document.addEventListener("turbo:frame-load", (event) => {
  if (event.target.id === "ndjson-preview") renderNdjsonPreviews(event.target)
})

// Open the preview modal alongside Turbo's frame load. Bootstrap's declarative
// data-bs-toggle cannot be used here: it prevents the click's default action,
// which makes Turbo ignore the link and the frame never loads.
document.addEventListener("click", (event) => {
  const link = event.target.closest('[data-turbo-frame="ndjson-preview"]')
  if (!link) return

  const modalElement = document.getElementById("ndjson-preview-modal")
  if (modalElement) window.bootstrap.Modal.getOrCreateInstance(modalElement).show()
})

// Show the raw $bulk-publish manifest (embedded in the page) in the same modal
document.addEventListener("click", (event) => {
  if (!event.target.closest("#view-raw-manifest")) return

  const frame = document.getElementById("ndjson-preview")
  const source = document.getElementById("manifest-source")
  const modalElement = document.getElementById("ndjson-preview-modal")
  if (!frame || !source || !modalElement || !window.JSONFormatter) return

  const header = document.createElement("div")
  header.className = "d-flex justify-content-between align-items-center mb-3"
  header.innerHTML = '<span>Raw <strong>$bulk-publish</strong> manifest</span>'
  const openLink = document.createElement("a")
  openLink.href = source.dataset.url
  openLink.target = "_blank"
  openLink.rel = "noopener"
  openLink.className = "btn btn-sm btn-outline-secondary"
  openLink.textContent = "Open raw JSON"
  header.appendChild(openLink)

  const entry = document.createElement("div")
  entry.className = "ndjson-entry border rounded p-2 bg-body-tertiary"
  entry.appendChild(new JSONFormatter(JSON.parse(source.textContent), 2, { theme: "dark" }).render())

  frame.replaceChildren(header, entry)
  window.bootstrap.Modal.getOrCreateInstance(modalElement).show()
})

document.addEventListener("turbo:load", () => {
  initializeTooltips()
  initializeCompareProgress()
})
