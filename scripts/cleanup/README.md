# System Scripts

System-level scripts for macOS. Tasks like permission resets, status checks, and admin tools.  
Use with caution — some scripts may require `sudo` or elevated privileges.

---

### `uninstall.sh`

A comprehensive macOS app cleanup script designed for **macOS 13 Ventura and later**.  
Detects and removes residual files from both user and system-level directories after uninstalling apps.

**Features:**
- Dry run mode to preview deletions
- Style mode with ASCII branding (“genorts mode”)
- Auto-detects bundle ID from dragged `.app` icons
- Skips any files/folders containing “apple” in the name (case-insensitive)
- Prompts before deleting system-level files
- Optional sudo retry for failed deletions
- Displays human-readable space savings at the end
- Tested on macOS Ventura and Sonoma — expected to work on macOS 15 Sequoia

> No third-party dependencies. Uses only built-in macOS tools (`find`, `awk`, `du`, `rm`, `PlistBuddy`, `sudo`).

**Usage:**  
Run manually from Terminal:  
```
./uninstall.sh
```
Follow the prompts to enable style mode, perform a dry run, and specify the app to clean up.
