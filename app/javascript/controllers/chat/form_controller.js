import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="chat--form"
export default class extends Controller {
  reset() {
    this.element.reset();
    this.element.querySelector("textarea").focus();
  }
}
