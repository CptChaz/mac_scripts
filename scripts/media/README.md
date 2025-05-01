# Media Scripts

Scripts for media conversion, compression, and metadata cleanup using tools like `ffmpeg` and `ImageMagick`.  
Tailored for macOS workflows and optimized for terminal-based batch processing.

---

### Included Scripts

#### `batch_convert_heic.sh`
Converts all `.HEIC` images in the current directory to `.JPG` format (90% quality) using ImageMagick.  
After verifying successful conversion, it deletes the original `.HEIC` files.

- Tested on: macOS 15.4.1  
- Dependencies: Homebrew, ImageMagick (with HEIC support via `libheif`)  
- Status: Tested

---

More media-focused scripts coming soon...
