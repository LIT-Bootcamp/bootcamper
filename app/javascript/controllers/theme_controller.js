import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "bootcamper-theme"
const MODES = ["system", "light", "dark"]

export default class extends Controller {
  static targets = ["select"]

  connect() {
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.mediaQuery.addEventListener("change", this.systemPreferenceChanged)
    this.apply()
  }

  disconnect() {
    this.mediaQuery?.removeEventListener("change", this.systemPreferenceChanged)
  }

  changed(event) {
    const mode = event.target.value
    if (!MODES.includes(mode)) return

    try {
      window.localStorage.setItem(STORAGE_KEY, mode)
    } catch (_error) {
      // Private browsing and restricted storage must not break theming.
    }
    this.apply()
  }

  get mode() {
    try {
      const storedMode = window.localStorage.getItem(STORAGE_KEY)
      return MODES.includes(storedMode) ? storedMode : "dark"
    } catch (_error) {
      return "dark"
    }
  }

  get resolvedTheme() {
    if (this.mode === "light") return "light"
    if (this.mode === "dark") return "dark"

    return this.mediaQuery.matches ? "dark" : "light"
  }

  apply() {
    document.documentElement.dataset.theme = this.resolvedTheme
    this.selectTarget.value = this.mode
    this.selectTarget.setAttribute("aria-label", `Color theme: ${this.mode}`)
  }

  systemPreferenceChanged = () => {
    if (this.mode === "system") this.apply()
  }
}
