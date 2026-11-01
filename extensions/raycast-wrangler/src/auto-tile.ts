import { showHUD } from "@raycast/api";
import { exec } from "child_process";

export default async function Command() {
  exec("/usr/bin/osascript -e 'tell application \"System Events\" to tell process \"Wrangler\" to click menu bar item 1 of menu bar 2'", () => {});
  // Fallback direct CLI
  exec("/usr/local/bin/wrangler-cli snap full || true", async () => {
    await showHUD("Wrangler: Auto-Tiling Desktop");
  });
}
