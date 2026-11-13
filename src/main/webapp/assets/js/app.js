/* ==========================================================================
   CampusClubSystem — Client-Side UI Interactions (Vanilla JavaScript)
   - Persistent Light / Dark theme toggle (stores ONLY 'light' or 'dark')
   - Accessible Show / Hide password toggle
   - Client-side validation helper & password confirmation match feedback
   - Confirmation dialog before destructive actions
   ========================================================================== */

(function () {
    "use strict";

    const THEME_STORAGE_KEY = "campusflow-theme";

    function getCurrentTheme() {
        return document.documentElement.getAttribute("data-bs-theme") === "dark" ? "dark" : "light";
    }

    function applyTheme(theme) {
        const normalized = theme === "dark" ? "dark" : "light";
        document.documentElement.setAttribute("data-bs-theme", normalized);
        try {
            localStorage.setItem(THEME_STORAGE_KEY, normalized);
        } catch (err) {
            // Ignore storage errors in restricted private-browsing modes
        }
        document.querySelectorAll("[data-theme-toggle]").forEach(function (btn) {
            const icon = btn.querySelector("i");
            const isDark = normalized === "dark";
            btn.setAttribute("aria-label", isDark ? "Switch to light mode" : "Switch to dark mode");
            btn.setAttribute("title", isDark ? "Switch to light mode" : "Switch to dark mode");
            if (icon) {
                icon.className = isDark ? "bi bi-sun-fill text-warning" : "bi bi-moon-stars-fill";
            }
        });
    }

    document.addEventListener("DOMContentLoaded", function () {
        // Initialize theme toggle button icons
        applyTheme(getCurrentTheme());

        document.querySelectorAll("[data-theme-toggle]").forEach(function (btn) {
            btn.addEventListener("click", function () {
                applyTheme(getCurrentTheme() === "dark" ? "light" : "dark");
            });
        });

        // Show / Hide password controls
        document.querySelectorAll("[data-toggle-password]").forEach(function (btn) {
            btn.addEventListener("click", function () {
                const targetId = btn.getAttribute("data-toggle-password");
                const input = document.getElementById(targetId);
                if (!input) {
                    return;
                }
                const revealing = input.type === "password";
                input.type = revealing ? "text" : "password";
                btn.setAttribute("aria-label", revealing ? "Hide password" : "Show password");
                const icon = btn.querySelector("i");
                if (icon) {
                    icon.className = revealing ? "bi bi-eye-slash" : "bi bi-eye";
                }
            });
        });

        // Password confirmation match check on forms with [data-match-password]
        document.querySelectorAll("input[data-match-password]").forEach(function (confirmInput) {
            const sourceId = confirmInput.getAttribute("data-match-password");
            const sourceInput = document.getElementById(sourceId);
            if (!sourceInput) {
                return;
            }
            const syncValidity = function () {
                if (confirmInput.value && confirmInput.value !== sourceInput.value) {
                    confirmInput.setCustomValidity("Passwords do not match.");
                } else {
                    confirmInput.setCustomValidity("");
                }
            };
            sourceInput.addEventListener("input", syncValidity);
            confirmInput.addEventListener("input", syncValidity);
        });

        // Bootstrap client-side validation styling
        document.querySelectorAll("form.needs-validation").forEach(function (form) {
            form.addEventListener("submit", function (event) {
                if (!form.checkValidity()) {
                    event.preventDefault();
                    event.stopPropagation();
                }
                form.classList.add("was-validated");
            });
        });

        // Confirmation prompt before destructive form submissions
        document.querySelectorAll("form[data-confirm]").forEach(function (form) {
            form.addEventListener("submit", function (event) {
                const message = form.getAttribute("data-confirm") || "Are you sure you want to proceed?";
                if (!window.confirm(message)) {
                    event.preventDefault();
                }
            });
        });
    });
})();
