// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import { registerServiceWorker, captureInstallPrompt, markLoadedImages } from "./lib/pwa"

registerServiceWorker()
captureInstallPrompt()
markLoadedImages()
