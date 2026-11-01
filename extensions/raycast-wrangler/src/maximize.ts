import { showHUD } from "@raycast/api";
import { exec } from "child_process";

export default async function Command() {
  exec("/usr/bin/osascript -e 'tell application \"System Events\" to key code 36 using {control down, option down}'", async () => {
    await showHUD("Wrangler: Maximized Window");
  });
}
