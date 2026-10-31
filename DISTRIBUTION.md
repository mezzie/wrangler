# Wrangler Distribution & Launch Plan

Checklist and channels to promote and distribute Wrangler to Mac users and developers.

---

## 1. Directories & Awesome Lists (Evergreen Traffic)

- [ ] **open-source-mac-os-apps** ([Repo](https://github.com/serhii-londar/open-source-mac-os-apps))
  - Submit Pull Request adding Wrangler under `Window Management`.
- [ ] **macoswm.com** ([Repo](https://github.com/stig/macoswm.com))
  - Submit Pull Request adding Wrangler to the curated directory of macOS window managers.
- [ ] **awesome-mac** ([Repo](https://github.com/jaywcjlove/awesome-mac))
  - Submit Pull Request under Utilities / Window Managers.
- [ ] **AlternativeTo.net** ([Site](https://alternativeto.net))
  - Create listing for Wrangler.
  - Tag as free & open-source alternative to **Lasso**, **SpaceJump**, **Moom**, and **Magnet**.

---

## 2. Package Managers

- [ ] **Homebrew Cask** (`homebrew/homebrew-cask`)
  - Create cask formula so users can install via:
    ```bash
    brew install --cask wrangler
    ```

---

## 3. Community Launch

- [ ] **Reddit: `r/macapps`**
  - **Title**: *I built Wrangler: a free, open-source window grid manager for macOS (Lasso alternative)*
  - **Content**: Short 10-second demo GIF showing `⌥ Space` grid summon, cell drag, and instant snap. Link to GitHub releases.
- [ ] **Hacker News: Show HN**
  - **Title**: *Show HN: Wrangler – Open-source window grid manager for macOS (Native Swift, no SIP disable)*
  - **Content**: Technical breakdown: pure AXUIElement + AppKit + SwiftUI, zero private hacks, respects privacy, lightweight.
- [ ] **Product Hunt**
  - Free launch under "Developer Tools", "Mac Utilities", and "Open Source".

---

## 4. Assets Checklist

- [ ] 10-15s screen recording / demo GIF of grid overlay in action.
- [ ] High-resolution app icon (1024x1024 PNG / ICNS).
- [ ] Direct download badge linking to latest release DMG.
