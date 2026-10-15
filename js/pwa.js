/* pwa.js - makes OpenLibrary installable as an app.
   Registers the service worker (offline + instant repeat loads) and wires
   up the "Install app" button that renderNavbar() adds to every page. */

// Register the service worker once per page load.
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("sw.js").catch(() => { /* offline support just won't be available */ });
  });
}

// The browser fires this when it decides the site is installable. We save
// the event and show our own "Install app" button instead of waiting for
// the browser's own (easy to miss) address-bar icon.
let deferredInstallPrompt = null;

window.addEventListener("beforeinstallprompt", (event) => {
  event.preventDefault();
  deferredInstallPrompt = event;
  document.querySelectorAll(".install-btn").forEach((btn) => { btn.hidden = false; });
});

// Called by the Install button in the navbar (see common.js).
async function promptInstall() {
  if (!deferredInstallPrompt) return;
  document.querySelectorAll(".install-btn").forEach((btn) => { btn.hidden = true; });
  deferredInstallPrompt.prompt();
  await deferredInstallPrompt.userChoice;
  deferredInstallPrompt = null;
}

// Once installed (from this button or the browser's own UI), hide the button for good.
window.addEventListener("appinstalled", () => {
  deferredInstallPrompt = null;
  document.querySelectorAll(".install-btn").forEach((btn) => { btn.hidden = true; });
});
