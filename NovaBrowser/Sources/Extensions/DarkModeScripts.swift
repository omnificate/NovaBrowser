// DarkModeScripts.swift
// NovaBrowser - Force dark mode on web pages

import Foundation

enum DarkModeScripts {
    static let injectionScript = """
    (function() {
        // Check if the page already supports dark mode
        var darkModeMedia = window.matchMedia('(prefers-color-scheme: dark)');
        if (darkModeMedia.matches) return;

        var style = document.createElement('style');
        style.id = 'nova-dark-mode';
        style.textContent = `
            html {
                filter: invert(1) hue-rotate(180deg) !important;
                background: #111 !important;
            }
            img, video, canvas, svg, picture,
            [style*="background-image"],
            iframe {
                filter: invert(1) hue-rotate(180deg) !important;
            }
            /* Preserve images in media elements */
            img[src$=".svg"] {
                filter: invert(1) hue-rotate(180deg) brightness(1.1) !important;
            }
            /* Fix common issues */
            input, textarea, select {
                background-color: #333 !important;
                color: #eee !important;
                border-color: #555 !important;
            }
            ::placeholder {
                color: #999 !important;
            }
        `;

        if (document.head) {
            document.head.appendChild(style);
        } else {
            document.addEventListener('DOMContentLoaded', function() {
                document.head.appendChild(style);
            });
        }
    })();
    """
}
