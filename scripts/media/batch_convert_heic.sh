#!/bin/bash

# Author: Cpt. Chaz
# Created: 2025-04-30
# Version Number: V 1.0
# Description: Converts all .HEIC images in the current directory to .JPG (90% quality) using ImageMagick, then deletes the originals if conversion is successful.
# OS Version: macOS 15.4.1
# Dependancies: ImageMagick (with HEIC support via libheif)
# Status: Tested
#
# Credits:
#  - https://imagemagick.org
#
# - This script was created with the help of ChatGPT, an OpenAI language model.
#
# Directions:
# 1. Install Homebrew: https://brew.sh
# 2. Install ImageMagick: `brew install imagemagick`
# 3. Make the script executable: `chmod +x /Users/yourname/Documents/scripts/bash/batch_convert_heic.sh`
# 4. Add an alias to ~/.zshrc:
#    `alias heic='/Users/yourname/Documents/scripts/bash/batch_convert_heic.sh'`
# 5. Run `source ~/.zshrc`
# 6. From any directory containing .HEIC files, type: `heic`

start_time=$(date +%s)

echo "========================================="
echo "  BATCH .HEIC TO .JPG CONVERTER - v1.0   "
echo "========================================="
echo ""

total=$(find . -maxdepth 1 -type f \( -iname "*.heic" \) | wc -l)
count=0
converted=0
deleted=0
skipped=0

if [ "$total" -eq 0 ]; then
    echo "No .HEIC files found in this directory."
    exit 0
fi

echo "Found $total .HEIC files to process."
echo ""

for f in *; do
    [ -f "$f" ] || continue
    ext="${f##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    if [ "$ext_lower" = "heic" ]; then
        output="${f%.*}.jpg"
        echo "[`printf "%3d" $((++count))`/$total] Converting $f -> $output"
        magick "$f" -quality 90 "$output"
        if [ $? -eq 0 ]; then
            ((converted++))
        else
            echo "    !! Conversion failed for $f"
            ((skipped++))
        fi
    fi
done

echo ""
echo "Conversion complete. Starting verification and cleanup..."
echo ""

count=0
for f in *; do
    [ -f "$f" ] || continue
    ext="${f##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    if [ "$ext_lower" = "heic" ]; then
        output="${f%.*}.jpg"
        ((count++))
        if [ -f "$output" ]; then
            echo "[`printf "%3d" $count`] Verified $output, deleting $f"
            rm -f "$f"
            ((deleted++))
        else
            echo "[`printf "%3d" $count`] Missing $output, keeping $f"
            ((skipped++))
        fi
    fi
done

end_time=$(date +%s)
elapsed=$((end_time - start_time))

echo ""
echo "========================================="
echo "              SUMMARY REPORT             "
echo "========================================="
printf "%-26s %4d\n" "Total .HEIC files found :" "$total"
printf "%-26s %4d\n" "Successfully converted  :" "$converted"
printf "%-26s %4d\n" "Deleted after verify    :" "$deleted"
printf "%-26s %4d\n" "Skipped (errors/missing):" "$skipped"
echo "========================================="
echo "Total time elapsed: ${elapsed} seconds"
