#!/bin/bash

# Author: [Cpt. Chaz]
# Created: [04/13/25]
# Revised: [04/13/25]
# Description: This script assists in fully removing macOS applications by searching for and optionally deleting leftover files at both user- and system-level locations.
# Usage: Drag an app into the terminal when prompted, or manually enter the app name. Run in Terminal. Includes dry run mode for previewing deletions before committing.
#   How It Works:
#     1. Prompts the user to confirm dry run mode and style mode (ASCII output).
#     2. If the app still exists, its bundle ID is extracted to target related files.
#     3. Scans user-level and system-level locations for matching files/folders.
#     4. Skips anything with "apple" in the name for safety.
#     5. Optionally deletes system-level matches after confirmation.
#     6. Displays summary with human-readable space savings.
#
# Status: Tested on Mac OS 13.x
#
# Credits:
# - This script was developed with the assistance of ChatGPT 4o, an OpenAI language model.


echo ""
echo "uninstall.sh v1.2.5 – Created April 2025"
echo ""

spinner_running=false
spinner_pid=""
DELETED_FILE_COUNT=0
DELETED_BYTES=0
SUDO_DELETED_COUNT=0
DRY_RUN_MATCHES=()
DRY_RUN_BYTES=0
SYSTEM_MATCHES=()
FAILED_DELETES=()
STILL_FAILED_DELETES=()

trap 'stop_spinner; echo; echo "Script interrupted."; exit 1' INT

show_spinner() {
  local message="$1"
  local delay=0.2
  local frames=("" "." ".." "...")
  spinner_running=true
  (
    i=0
    while $spinner_running; do
      printf "\r%s [ Scanning%s ]" "$message" "${frames[i]}"
      sleep $delay
      i=$(( (i + 1) % 4 ))
    done
  ) &
  spinner_pid=$!
}

stop_spinner() {
  if [ -n "$spinner_pid" ]; then
    spinner_running=false
    kill "$spinner_pid" &>/dev/null
    wait "$spinner_pid" 2>/dev/null
    printf "\r\033[K"
  fi
}

STYLE_MODE=false
while true; do
  read -p "Run with style? (y/n): " STYLE_ANSWER
  if [[ "$STYLE_ANSWER" =~ ^[Yy]$ ]]; then
    STYLE_MODE=true
    echo ""
    echo " __  __           _       _        "
    echo "|  \\/  | ___   __| |_   _| | ___   "
    echo "| |\\/| |/ _ \\ / _\` | | | | |/ _ \\  "
    echo "| |  | | (_) | (_| | |_| | |  __/  "
    echo "|_|  |_|\\___/ \\__,_|\\__,_|_|\\___|  "
    echo "        MAC APP CLEANUP TOOL       "
    echo ""
    echo "> genorts mode activated"
    echo ""
    break
  elif [[ "$STYLE_ANSWER" =~ ^[Nn]$ ]]; then
    break
  else
    echo "Please enter 'y' or 'n'."
  fi
done

DRY_RUN=false
while true; do
  read -p "Perform a dry run? (y/n): " DRY_ANSWER
  if [[ "$DRY_ANSWER" =~ ^[Yy]$ ]]; then
    DRY_RUN=true
    break
  elif [[ "$DRY_ANSWER" =~ ^[Nn]$ ]]; then
    break
  else
    echo "Please enter 'y' or 'n'."
  fi
done

while true; do
  read -p "Have you already deleted the app? (y/n): " APP_EXISTS
  if [[ "$APP_EXISTS" =~ ^[Yy]$ ]]; then
    read -p "Enter the name of the app: " MATCH_KEY
    break
  elif [[ "$APP_EXISTS" =~ ^[Nn]$ ]]; then
    echo ""
    echo "Please drag the .app icon here, then press Enter:"
    read -r APP_PATH
    APP_PATH_CLEANED=$(eval echo "$APP_PATH")
    if [ ! -e "$APP_PATH_CLEANED/Contents/Info.plist" ]; then
      echo "Could not find Info.plist at: $APP_PATH_CLEANED"
      echo "Falling back to manual app name input."
      read -p "Enter the name of the app: " MATCH_KEY
    else
      BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$APP_PATH_CLEANED/Contents/Info.plist" 2>/dev/null)
      if [[ -z "$BUNDLE_ID" ]] || [[ "$BUNDLE_ID" == Usage:* ]]; then
        echo "Could not extract bundle identifier."
        fallback_name=$(basename "$APP_PATH_CLEANED")
        fallback_name="${fallback_name%.app}"
        MATCH_KEY="$fallback_name"
        echo "Using fallback app name: \"$MATCH_KEY\""
      else
        echo "Found bundle identifier: $BUNDLE_ID"
        MATCH_KEY="$BUNDLE_ID"
      fi
    fi
    break
  else
    echo "Please enter 'y' or 'n'."
  fi
done

MATCH_KEY_LOWER=$(echo "$MATCH_KEY" | tr '[:upper:]' '[:lower:]')
MATCH_KEY_NORMALIZED=$(echo "$MATCH_KEY_LOWER" | tr -d '[:space:]')
DARWIN_CACHE=$(getconf DARWIN_USER_CACHE_DIR | sed 's:/$::')
DARWIN_TEMP=$(getconf DARWIN_USER_TEMP_DIR | sed 's:/$::')

USER_DIRS=( "$HOME/Library/Application Support" "$HOME/Library/Application Support/CrashReporter" "$HOME/Library/Caches"
  "$HOME/Library/Containers" "$HOME/Library/Logs" "$HOME/Library/LaunchAgents" "$HOME/Library/Saved Application State"
  "$HOME/Library/Group Containers" "$HOME/Library/WebKit" "$HOME/Library/HTTPStorages" "$HOME/Library/Cookies"
  "$HOME/Library/Preferences" "$HOME/Library/Preferences/ByHost" "$HOME/Library/Application Scripts" )

SYSTEM_DIRS=( "/Library/Application Support" "/Library/Application Support/CrashReporter" "/Library/Caches"
  "/Library/Containers" "/Library/Logs" "/Library/LaunchAgents" "/Library/LaunchDaemons" "/Library/Preferences"
  "/Library/PrivilegedHelperTools" "/Library/Extensions" "/private/var/db/receipts" "/usr/local/bin" "/usr/local/etc"
  "/usr/local/sbin" "/usr/local/share" "/usr/local/var" "$DARWIN_CACHE" "$DARWIN_TEMP" )
echo ""
echo "========================================================"
echo "           macOS App Cleanup Script (Manual)            "
echo "========================================================"
echo ""
echo "Searching for remnants of: \"$MATCH_KEY\""
echo "Dry run mode: $DRY_RUN"
echo ""

process_matches() {
  local SCOPE="$1"
  shift
  local TARGET_PATHS=("$@")

  for DIR in "${TARGET_PATHS[@]}"; do
    [ -d "$DIR" ] || continue
    echo "Scanning: $DIR"

    while IFS= read -r -d '' ITEM; do
      ITEM_BASENAME=$(basename "$ITEM" | tr '[:upper:]' '[:lower:]')
      [[ "$ITEM_BASENAME" == *apple* ]] && continue

      if [[ "$SCOPE" == "system" ]]; then
        SYSTEM_MATCHES+=("$ITEM")
        continue
      fi

      ITEM_SIZE=$(du -ks "$ITEM" 2>/dev/null | cut -f1)
      ITEM_HUMAN=$(du -sh "$ITEM" 2>/dev/null | cut -f1)
      echo "  Found: $ITEM ($ITEM_HUMAN)"

      if [ "$DRY_RUN" = false ]; then
        rm -rf "$ITEM" 2>/dev/null
        if [ $? -eq 0 ]; then
          echo "    Deleted"
          DELETED_FILE_COUNT=$((DELETED_FILE_COUNT + 1))
          DELETED_BYTES=$((DELETED_BYTES + ITEM_SIZE * 1024))
        else
          echo "    Failed to delete"
          FAILED_DELETES+=("$ITEM")
        fi
      else
        DRY_RUN_MATCHES+=("$ITEM")
        DRY_RUN_BYTES=$((DRY_RUN_BYTES + ITEM_SIZE * 1024))
      fi
    done < <(find "$DIR" \( -iname "*$MATCH_KEY_LOWER*" -o -iname "*$MATCH_KEY_NORMALIZED*" \) -print0 2>/dev/null)
    echo ""
  done
}

$STYLE_MODE && show_spinner "Processing user-level directories"
process_matches user "${USER_DIRS[@]}"
$STYLE_MODE && stop_spinner

$STYLE_MODE && show_spinner "Processing system-level directories"
process_matches system "${SYSTEM_DIRS[@]}"
$STYLE_MODE && stop_spinner

if [ "${#SYSTEM_MATCHES[@]}" -gt 0 ]; then
  echo ""
  echo "--------------------------------------------------------"
  echo "The following system-level files matched \"$MATCH_KEY\":"
  for match in "${SYSTEM_MATCHES[@]}"; do
    echo "  $match"
  done
  echo ""

  while true; do
    read -p "Do you want to delete these system-level files? (y/n): " SYS_CONFIRM
    if [[ "$SYS_CONFIRM" =~ ^[Yy]$ ]]; then
      echo ""
      echo "Deleting system-level matches..."
      for ITEM in "${SYSTEM_MATCHES[@]}"; do
        ITEM_BASENAME=$(basename "$ITEM" | tr '[:upper:]' '[:lower:]')
        [[ "$ITEM_BASENAME" == *apple* ]] && continue

        ITEM_SIZE=$(du -ks "$ITEM" 2>/dev/null | cut -f1)
        rm -rf "$ITEM" 2>/dev/null
        if [ $? -eq 0 ]; then
          echo "  Deleted: $ITEM"
          DELETED_FILE_COUNT=$((DELETED_FILE_COUNT + 1))
          DELETED_BYTES=$((DELETED_BYTES + ITEM_SIZE * 1024))
        else
          echo "  Failed to delete: $ITEM"
          FAILED_DELETES+=("$ITEM")
        fi
      done
      break
    elif [[ "$SYS_CONFIRM" =~ ^[Nn]$ ]]; then
      echo "System-level deletions skipped."
      break
    else
      echo "Please enter 'y' or 'n'."
    fi
  done
else
  echo "No system-level matches found."
fi

echo "--------------------------------------------------------"
echo "Cleanup complete."
echo ""

if [ "$DRY_RUN" = false ]; then
  echo "Summary:"
  echo "  Files and folders deleted: $DELETED_FILE_COUNT"
  echo -n "  Total space freed: "
  echo "$DELETED_BYTES" | awk '{ byte=$1; kb=byte/1024; mb=kb/1024; gb=mb/1024; if (gb>=1) printf "%.2f GB\\n", gb; else if (mb>=1) printf "%.2f MB\\n", mb; 
else if (kb>=1) printf "%.2f KB\\n", kb; else print byte " B"}'

  if [ "${#FAILED_DELETES[@]}" -gt 0 ]; then
    echo ""
    echo "The following files could not be deleted:"
    for file in "${FAILED_DELETES[@]}"; do
      echo "  $file"
    done
    echo ""

    while true; do
      read -p "Retry these using sudo? (y/n): " SUDO_RETRY
      if [[ "$SUDO_RETRY" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Attempting sudo deletion..."
        for file in "${FAILED_DELETES[@]}"; do
          sudo rm -rf "$file" 2>/dev/null
          if [ $? -eq 0 ]; then
            echo "  Sudo deleted: $file"
            SUDO_DELETED_COUNT=$((SUDO_DELETED_COUNT + 1))
          else
            echo "  Still failed: $file"
            STILL_FAILED_DELETES+=("$file")
          fi
        done
        break
      elif [[ "$SUDO_RETRY" =~ ^[Nn]$ ]]; then
        echo "Sudo retry skipped."
        STILL_FAILED_DELETES=("${FAILED_DELETES[@]}")
        break
      else
        echo "Please enter 'y' or 'n'."
      fi
    done

    echo ""
    echo "Sudo recovery complete."
    echo "  Files deleted with sudo: $SUDO_DELETED_COUNT"

    if [ "${#STILL_FAILED_DELETES[@]}" -gt 0 ]; then
      echo ""
      echo "The following files still could not be deleted:"
      for file in "${STILL_FAILED_DELETES[@]}"; do
        echo "  $file"
      done
    fi
  fi
else
  echo "Dry run summary:"
  echo "  Files and folders that would be deleted:"
  for match in "${DRY_RUN_MATCHES[@]}"; do
    echo "    $match"
  done
  echo -n "  Estimated space to be freed: "
  echo "$DRY_RUN_BYTES" | awk '{ byte=$1; kb=byte/1024; mb=kb/1024; gb=mb/1024; if (gb>=1) printf "%.2f GB\\n", gb; else if (mb>=1) printf "%.2f MB\\n", mb; 
else if (kb>=1) printf "%.2f KB\\n", kb; else print byte " B"}'
  echo "  No files were deleted."
fi

if [ "$STYLE_MODE" = true ]; then
  echo ""
  echo "  ____                        _       "
  echo " / ___| ___ _ __   ___  _ __| |_ ___ "
  echo "| |  _ / _ \\ '_ \\ / _ \\| '__| __/ __|"
  echo "| |_| |  __/ | | | (_) | |  | |_\\__ \\"
  echo " \\____|\\___|_| |_|\\___/|_|   \\__|___/"
  echo "         Mission Accomplished        "
  echo "         >> genorts complete"
fi

