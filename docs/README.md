# mac_scripts

This repository contains macOS utility scripts developed by **Cpt. Chaz** to assist with system maintenance, automation, and media handling. All scripts are tested on **macOS Monterey (12.x)** and later, and include clear usage instructions and built-in safety checks where applicable.

---

## Available Scripts

### `uninstall.sh`  
- **Status:** Tested  
- **Description:**  
  Fully removes a selected application from macOS, including support files in both user-level and system-level directories. Features:
  - Dry run mode for previewing deletions
  - Style mode toggle (minimal or "genorts mode" ASCII interface)
  - Auto-detection of bundle ID from a dragged `.app` file
  - Manual fallback if app is already deleted
  - Input validation for all prompts
  - Skips any file or folder with "apple" in the name (case-insensitive)
  - Final summary includes total disk space savings

- **Directions:**  
1. Open Terminal, drag the script into the window, and follow the prompts.

2. Make the script executable if needed:

  ```bash
  chmod +x uninstall.sh
  ```

Alternatively, navigate to the script location and call the script:
  ```
  ./uninstall.sh
  ```

---

### `batch_convert_heic.sh`
- **Status:** Tested  
- **Description:**  
  Recursively finds and batch-converts all `.heic` image files within a specified directory to `.jpg` format using the `sips` utility. Original `.heic` files are retained.

- **Directions:**  
1. Open Terminal.  
2. Make script executable if needed:

     ```bash
     chmod +x batch_convert_heic.sh
     ```

3. Run the script and provide a folder path when prompted, or pass the folder as an argument:

     ```bash
     ./batch_convert_heic.sh /path/to/folder
     ```

---

## Requirements

- macOS 12 or later
- `sips` utility (included with macOS)
- Terminal access with appropriate permissions

---

## Notes

- All scripts include standardized headers with versioning, changelog, usage, and credits.
- Scripts are designed to be run manually, not scheduled.
- Created and maintained by **Cpt. Chaz**, with the assistance of **ChatGPT**, an OpenAI language model.

---

## License

MIT License unless otherwise specified in individual script headers.
