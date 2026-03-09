#!/bin/bash

# --- CONFIGURATION ---
SEARCH_DIRS=(
    "$HOME/Downloads/"
    "$HOME/Desktop/"
    "$HOME/Documents/"
    "$HOME/dotfiles/"
    "$HOME/.config/"
)

EXCLUDES=("node_modules" ".cache" ".local" "venv" "target" "build" "dist" ".git")

RECENT_DB="$HOME/.vsc-recent.txt"
CACHE_FILE="$HOME/.cache/vsc_smart_cache_$USER"
CONFIG_HASH_FILE="$HOME/.cache/vsc_config_hash_$USER"
CACHE_TTL=900

H_START="<span color='#ff9d00'><b>"
H_END="</b></span>|ns"
NESTED_HIDDEN_FILTER='/\.[^/]+.*/\.[^/]+'

mkdir -p "$(dirname "$RECENT_DB")"
touch "$RECENT_DB"

FD_EXCLUDES=()
for x in "${EXCLUDES[@]}"; do FD_EXCLUDES+=(--exclude "$x"); done

# --- HELPERS ---
msg() {
    local message="$1" icon="${2:-info}" expire="${3:-2000}"
    local last_id=$(cat "/tmp/vsc_notify_id_$USER" 2>/dev/null || echo 0)
    notify-send -p -r "$last_id" -i "$icon" -t "$expire" "VSC Project Manager" "$message" >"/tmp/vsc_notify_id_$USER"
}

norm_path() {
    realpath -s "$1" 2>/dev/null | sed 's|/*$||'
}

# --- CACHING ENGINE ---
refresh_cache() {
    local target_dir="${1:-}"
    local is_bg="${2:-false}"

    [[ "$is_bg" == "true" ]] && msg "Updating project cache..." "view-refresh-symbolic" 1500

    local results
    if [ -n "$target_dir" ]; then
        results=$( (
            fd -L -H -t d "${FD_EXCLUDES[@]}" '^.git$' "$target_dir" --max-depth 4 -x echo '{//}|1'
            fd -L -H -t d "${FD_EXCLUDES[@]}" --max-depth 2 . "$target_dir" | grep -vE "$NESTED_HIDDEN_FILTER" | sed 's/$/|0/'
        ))

        [ -f "$CACHE_FILE" ] && sed -i "\|^$target_dir|d" "$CACHE_FILE"
        while read -r line; do
            [[ -z "$line" ]] && continue
            p_norm=$(norm_path "${line%|*}")
            [ -n "$p_norm" ] && echo "$p_norm|${line#*|}" >>"$CACHE_FILE"
        done <<<"$results"
    else
        (
            fd -L -H -t d "${FD_EXCLUDES[@]}" '^.git$' "${SEARCH_DIRS[@]}" --max-depth 4 -x echo '{//}|1'
            fd -L -H -t d "${FD_EXCLUDES[@]}" --max-depth 2 . "${SEARCH_DIRS[@]}" | grep -vE "$NESTED_HIDDEN_FILTER" | sed 's/$/|0/'
        ) | while read -r line; do
            p_norm=$(norm_path "${line%|*}")
            [ -n "$p_norm" ] && echo "$p_norm|${line#*|}"
        done >"$CACHE_FILE"
        echo "${SEARCH_DIRS[@]}" | md5sum >"$CONFIG_HASH_FILE"
    fi
    sort -u -o "$CACHE_FILE" "$CACHE_FILE"
}

# --- RANKER ---
get_ranked_projects() {
    local counts_logic=""
    for i in "${!SEARCH_DIRS[@]}"; do
        dir="${SEARCH_DIRS[$i]}"
        count=$(grep -c "^$dir" "$RECENT_DB")
        counts_logic+="${dir},${count},${i} "
    done

    awk -v counts="$counts_logic" -F'|' '
    BEGIN { split(counts, arr, " "); for (i in arr) { split(arr[i], pair, ","); scores[pair[1]] = pair[2]; pos[pair[1]] = pair[3] } }
    {
        path = $1; is_git = $2; score = 0; rank = 999;
        for (s in scores) { if (index(path, s) == 1) { if (scores[s] >= score) { score = scores[s]; if (pos[s] < rank) rank = pos[s] } } }
        print score "|" rank "|" is_git "|" path
    }' "$CACHE_FILE" | sort -t'|' -k1,1rn -k2,2n -k3,3rn -k4,4 | cut -d'|' -f3-
}

# --- VALIDATION ---
validate_data() {
    if [ -f "$RECENT_DB" ]; then
        tmp_recent=$(mktemp)
        while read -r line; do [ -d "$line" ] && echo "$line"; done <"$RECENT_DB" | awk '!seen[$0]++' >"$tmp_recent"
        mv "$tmp_recent" "$RECENT_DB"
    fi

    local current_hash=$(echo "${SEARCH_DIRS[@]}" | md5sum)
    local old_hash=$(cat "$CONFIG_HASH_FILE" 2>/dev/null)
    local cache_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)

    if [ ! -f "$CACHE_FILE" ] || [ "$current_hash" != "$old_hash" ]; then
        (refresh_cache "" "true" &)
    else
        for d in "${SEARCH_DIRS[@]}"; do
            if [ -d "$d" ] && [ $(stat -c %Y "$d") -gt $cache_mtime ]; then
                refresh_cache "$d" "false"
                touch "$CACHE_FILE"
            fi
        done
        tmp_cache=$(mktemp)
        while IFS='|' read -r p_norm flag; do [ -d "$p_norm" ] && echo "$p_norm|$flag"; done <"$CACHE_FILE" >"$tmp_cache"
        mv "$tmp_cache" "$CACHE_FILE"
    fi
}

validate_data
SCOPE_DIR=""

while true; do
    mapfile -t RECENT_ARRAY < <(tac "$RECENT_DB" | head -n 15)
    MENU_ITEMS=()

    if [ -z "$SCOPE_DIR" ]; then
        PROMPT="[Global] (Ctrl-O: Direct Open)"
        MENU_ITEMS+=("${H_START}─── RECENT PROJECTS ───${H_END}")
        for r in "${RECENT_ARRAY[@]}"; do [ -d "$r" ] && MENU_ITEMS+=("⌚ $r/"); done
        MENU_ITEMS+=("${H_START}─── DISCOVERED PROJECTS ───${H_END}")

        while read -r line; do
            is_git="${line%%|*}"
            p_norm="${line#*|}"
            [[ -z "$p_norm" ]] || [ ! -d "$p_norm" ] && continue
            is_redundant=false
            for r_norm in "${RECENT_ARRAY[@]}"; do
                if [[ "$p_norm" == "$r_norm" ]] || [[ "$p_norm" == "$r_norm"/* ]]; then
                    is_redundant=true
                    break
                fi
            done
            if [ "$is_redundant" = false ]; then
                icon=$([[ "$is_git" == "1" ]] && echo "󰊢" || echo "󰉋")
                MENU_ITEMS+=("$icon $p_norm/")
            fi
        done < <(get_ranked_projects)
        MENU_ITEMS+=("${H_START}─── OPTIONS ───${H_END}" "󰑐 Force Refresh Cache")
    else
        PROMPT="[Exploring $(basename "$SCOPE_DIR")]"
        MENU_ITEMS+=("󰌍 .. [Go Back]" "󰩉 .. [Main Menu]")
        while read -r p; do
            pn=$(norm_path "$p")
            [ -z "$pn" ] && continue
            icon=$([ -d "$pn/.git" ] && echo "󰊢" || echo "󰉋")
            MENU_ITEMS+=("$icon $pn/")
        done < <(fd -L -H -t d --max-depth 1 "${FD_EXCLUDES[@]}" . "$SCOPE_DIR" | sort -V)
    fi

    # --- THE KEY FIX IS HERE ---
    # Added -kb-custom-1 "Control+o"
    SELECTED=$(printf "%s\n" "${MENU_ITEMS[@]}" |
        sed 's/|ns/\x00nonselectable\x1ftrue/' |
        rofi -dmenu -i -p "$PROMPT" -markup-rows -width 1200 -kb-custom-1 "Control+o")

    EXIT_CODE=$?

    # Exit if user hits Escape (Code 1)
    [[ $EXIT_CODE -eq 1 || -z "$SELECTED" ]] && exit 0

    if [[ "$SELECTED" == *"Force Refresh Cache"* ]]; then
        refresh_cache "" "true"
        continue
    fi

    [[ "$SELECTED" == *"Go Back"* ]] && {
        SCOPE_DIR=$(dirname "$SCOPE_DIR")
        continue
    }
    [[ "$SELECTED" == *"Main Menu"* ]] && {
        SCOPE_DIR=""
        continue
    }

    CLEAN_PATH=$(echo "$SELECTED" | sed 's/^[⌚󰊢󰉋󰌍󰩉] //' | sed 's|/$||')
    CLEAN_PATH=$(norm_path "$CLEAN_PATH")

    if [ ! -d "$CLEAN_PATH" ]; then
        msg "Directory no longer exists!" "dialog-error" 2000
        validate_data
        continue
    fi

    # If EXIT_CODE is 10, user pressed Ctrl-O. Open immediately.
    if [ "$EXIT_CODE" -eq 10 ]; then
        sed -i "\|^$CLEAN_PATH$|d" "$RECENT_DB"
        echo "$CLEAN_PATH" >>"$RECENT_DB"
        msg "Opening $(basename "$CLEAN_PATH")..." "vscode" 1500
        code "$CLEAN_PATH"
        exit 0
    fi

    # Otherwise, show confirmation menu
    CONFIRM=$(printf "1. Open in Code\n2. Explore Sub-folders\n3. Cancel" | rofi -dmenu -i -p "Action: $(basename "$CLEAN_PATH")" -width 400)
    case "$CONFIRM" in
    "1."*)
        sed -i "\|^$CLEAN_PATH$|d" "$RECENT_DB"
        echo "$CLEAN_PATH" >>"$RECENT_DB"
        msg "Opening $(basename "$CLEAN_PATH")..." "vscode" 1500
        code "$CLEAN_PATH"
        exit 0
        ;;
    "2."*)
        SCOPE_DIR="$CLEAN_PATH"
        continue
        ;;
    *) continue ;;
    esac
done
