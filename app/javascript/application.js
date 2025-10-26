// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
// import * as bootstrap from "bootstrap" // Commented out - causing importmap issues, tooltips are optional

import Rails from "@rails/ujs"
Rails.start()
