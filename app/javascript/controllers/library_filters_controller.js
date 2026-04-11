import { Controller } from "@hotwired/stimulus"

// Compatibility shim for stale precompiled assets that still import
// controllers/library_filters_controller. Current library filtering behavior
// lives in submit_on_keyup_controller.js.
export default class extends Controller {}
