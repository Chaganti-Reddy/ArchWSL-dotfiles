#!/bin/bash

# =============================================================================
# gitAutoCommitter.sh — Fast, intelligent AI-powered git committer
# =============================================================================
# - ONE model load for ALL files (batched inference)
# - GPU auto-detection: uses CUDA on Linux/Windows, Metal on Mac
# - Uses llama-cpp-python (pip) for easy CUDA support — no building from source
# - Qwen2.5-Coder-7B: code-specialized model
# - Smart fallback to rule-based messages if AI fails
# =============================================================================

set -uo pipefail

# --- Config 
CACHE_DIR="$HOME/.cache/ai-committer"
MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q4_k_m.gguf"
MODEL_PATH="$CACHE_DIR/qwen2.5-coder-7b.gguf"
VENV_DIR="$CACHE_DIR/venv"
PYTHON_BIN="$VENV_DIR/bin/python"
MAX_DIFF_CHARS=800   # per-file diff budget (keeps total tokens under context window)
AI_TIMEOUT=120
AI_DEBUG="${AI_DEBUG:-0}"

mkdir -p "$CACHE_DIR"

# --- Fix: use system libstdc++ (conda ships an older one lacking GLIBCXX_3.4.30)
if [ -f "/usr/lib/libstdc++.so.6" ]; then
    export LD_PRELOAD="/usr/lib/libstdc++.so.6:${LD_PRELOAD:-}"
fi

# --- Add all conda NVIDIA CUDA runtime libs (cublas, cudart, cusolver, etc.) 
for _conda_prefix in "$HOME/miniconda3" "$HOME/miniconda" "$HOME/anaconda3" "$HOME/anaconda"; do
    _nvidia_site="$_conda_prefix/lib/python3.11/site-packages/nvidia"
    if [ -d "$_nvidia_site" ]; then
        for _dir in "$_nvidia_site"/*/lib; do
            [ -d "$_dir" ] && export LD_LIBRARY_PATH="$_dir:${LD_LIBRARY_PATH:-}"
        done
        break
    fi
done

# --- Detect OS & GPU 
OS_TYPE=$(uname -s)
GPU_LAYERS=0
GPU_TYPE="cpu"

if [[ "$OS_TYPE" == "Darwin" ]]; then
    OS="mac"
    GPU_TYPE="metal"
    GPU_LAYERS=99
    echo "  GPU: Apple Silicon — Metal acceleration enabled"
elif [[ "$OS_TYPE" == *"MINGW"* || "$OS_TYPE" == *"MSYS"* ]]; then
    OS="windows"
else
    OS="linux"
fi

if [[ "${OS:-linux}" != "mac" ]]; then
    if command -v nvidia-smi &>/dev/null; then
        VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
        if [ -n "$VRAM" ] && [ "$VRAM" -gt 0 ] 2>/dev/null; then
            GPU_TYPE="cuda"
            GPU_LAYERS=99
            echo "  GPU: NVIDIA (${VRAM}MB VRAM) — CUDA enabled"
        fi
    elif command -v rocm-smi &>/dev/null || [ -d /opt/rocm ]; then
        GPU_TYPE="rocm"
        GPU_LAYERS=99
        echo "  GPU: AMD ROCm enabled"
    else
        echo "  GPU: none detected — using CPU"
    fi
fi

# --- Setup Python venv + llama-cpp-python 
setup_python_backend() {
    if [ ! -f "$PYTHON_BIN" ]; then
        echo "Setting up Python environment..."
        python3 -m venv "$VENV_DIR"
    fi

    if ! "$PYTHON_BIN" -c "import llama_cpp" &>/dev/null; then
        echo "Installing llama-cpp-python..."

        if [ "$GPU_TYPE" = "cuda" ]; then
            local cuda_ver="cu121"
            if command -v nvcc &>/dev/null; then
                local ver
                ver=$(nvcc --version 2>/dev/null | grep -oP "release \K[0-9]+" | head -1)
                case "$ver" in
                    11) cuda_ver="cu118" ;;
                    12) cuda_ver="cu121" ;;
                esac
            fi
            echo "  Installing CUDA ($cuda_ver) build of llama-cpp-python..."
            "$VENV_DIR/bin/pip" install llama-cpp-python \
                --extra-index-url "https://abetlen.github.io/llama-cpp-python/whl/$cuda_ver" \
                --quiet
        elif [ "$GPU_TYPE" = "metal" ]; then
            echo "  Installing Metal build of llama-cpp-python..."
            "$VENV_DIR/bin/pip" install llama-cpp-python \
                --extra-index-url "https://abetlen.github.io/llama-cpp-python/whl/metal" \
                --quiet
        else
            echo "  Installing CPU build of llama-cpp-python..."
            "$VENV_DIR/bin/pip" install llama-cpp-python --quiet
        fi
        echo "  Done."
    fi
}

# --- Download model 
download_model() {
    if [ ! -f "$MODEL_PATH" ]; then
        echo "Downloading Qwen2.5-Coder-7B model (~4.7GB, one-time)..."
        curl -L "$MODEL_URL" -o "$MODEL_PATH"
    fi
}

# --- Rule-based fallback 
rule_based_message() {
    local file=$1 status=$2
    local ext="${file##*.}"
    local base="${file##*/}"
    case "$status" in
        D)    echo "chore: remove $base" ;;
        A|??)
            case "$ext" in
                test|spec) echo "test: add tests for ${base%.*}" ;;
                md|txt|rst) echo "docs: add $base" ;;
                json|yaml|yml|toml) echo "chore: add $base config" ;;
                *) echo "feat: add $base" ;;
            esac ;;
        M|MM)
            case "$ext" in
                test|spec) echo "test: update tests in $base" ;;
                md|txt|rst) echo "docs: update $base" ;;
                json|yaml|yml|toml) echo "chore: update $base config" ;;
                *) echo "refactor: update $base" ;;
            esac ;;
        R*)   echo "refactor: rename to $base" ;;
        *)    echo "chore: update $base" ;;
    esac
}

# --- Collect diffs 
collect_changes() {
    local status_lines="$1"
    local payload=""
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local status file
        status=$(echo "$line" | awk '{print $1}')
        file=$(echo "$line" | awk '{print substr($0, index($0,$2))}' | sed 's/^ *//; s/^"\(.*\)"$/\1/')
        local diff_context=""
        case "$status" in
            D)
                diff_context="DELETED: $file" ;;
            A|??)
                # Try working tree first, then staged content
                diff_context="NEW FILE: $file
$(git diff --cached -- "$file" 2>/dev/null | grep '^+' | grep -v '^+++' | head -c "$MAX_DIFF_CHARS" | tr -d '\r')" ;;
            R*)
                diff_context="RENAMED to: $file" ;;
            *)
                # Check both staged and unstaged changes
                diff_context="MODIFIED: $file
$(( git diff --cached -- "$file"; git diff HEAD -- "$file" ) 2>/dev/null | grep '^[+-]' | grep -v '^[+-][+-][+-]' | head -c "$MAX_DIFF_CHARS" | tr -d '\r')" ;;
        esac
        payload+="---FILE---
PATH: $file
STATUS: $status
$diff_context
"
    done <<< "$status_lines"
    echo "$payload"
}

# --- Batched AI inference via Python 
generate_ai_messages_batch() {
    local all_diffs="$1"

    local tmp_diff
    tmp_diff=$(mktemp /tmp/ai-commit-diff.XXXXXX)
    echo "$all_diffs" > "$tmp_diff"

    local raw
    raw=$(timeout "$AI_TIMEOUT" "$PYTHON_BIN" - "$tmp_diff" "$MODEL_PATH" "$GPU_LAYERS" 2>/tmp/ai-commit-stderr.txt << 'PYEOF'
import sys

diff_file = sys.argv[1]
model_path = sys.argv[2]
n_gpu_layers = int(sys.argv[3])

with open(diff_file, encoding='utf-8', errors='replace') as f:
    all_diffs = f.read()

from llama_cpp import Llama

llm = Llama(
    model_path=model_path,
    n_gpu_layers=n_gpu_layers,
    n_ctx=16384,
    verbose=False,
)

SYSTEM = (
    "You are an expert engineer writing git commit messages from code diffs.\n"
    "Output EXACTLY one line per file in this format:\n"
    "filepath|||commit message\n\n"
    "Rules:\n"
    "- Use Conventional Commits: feat, fix, docs, refactor, test, chore, style, perf\n"
    "- Infer intent from the actual diff content\n"
    "- Be specific: prefer 'fix: handle null user in auth' over 'fix: update auth.js'\n"
    "- Max 72 chars per message. No quotes, no markdown, no extra text.\n"
    "- Output ONLY the filepath|||message lines, nothing else."
)

# Split into per-file chunks on the ---FILE--- separator
file_chunks = [c.strip() for c in all_diffs.split("---FILE---") if c.strip()]

# Group chunks so each batch stays well under the context window (~8000 chars each)
BATCH_CHAR_LIMIT = 6000
batches = []
current = []
current_len = 0
for chunk in file_chunks:
    if current and current_len + len(chunk) > BATCH_CHAR_LIMIT:
        batches.append("\n---FILE---\n".join(current))
        current = [chunk]
        current_len = len(chunk)
    else:
        current.append(chunk)
        current_len += len(chunk)
if current:
    batches.append("\n---FILE---\n".join(current))

for batch in batches:
    out = llm.create_chat_completion(
        messages=[
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": batch},
        ],
        max_tokens=2048,
        temperature=0.2,
    )
    print(out["choices"][0]["message"]["content"].strip())
PYEOF
    2>/dev/null || true)

    rm -f "$tmp_diff"

    if [ "$AI_DEBUG" = "1" ]; then
        echo "=== RAW MODEL OUTPUT ===" >&2
        echo "$raw" >&2
        echo "=== STDERR ===" >&2
        cat /tmp/ai-commit-stderr.txt >&2
        echo "========================" >&2
    fi

    echo "$raw" | grep "|||" | sed 's/^ *//; s/ *$//'
}

# --- Main 
echo ""
read -rp "Git repository path: " repo_path
if [ ! -d "$repo_path/.git" ]; then
    echo "Not a valid Git repository: $repo_path"
    exit 1
fi
cd "$repo_path"

current_branch=$(git rev-parse --abbrev-ref HEAD)
read -rp "Branch to push to (default: $current_branch): " input_branch
branch="${input_branch:-$current_branch}"

# --- Setup (one-time) 
setup_python_backend
download_model

# --- Capture git status ONCE (skip files in nested git repos / stow targets) 
GIT_STATUS_RAW=$(git status --porcelain)
GIT_STATUS=""
while IFS= read -r line; do
    [ -z "$line" ] && continue
    file=$(echo "$line" | awk '{print substr($0, index($0,$2))}' | sed 's/^ *//; s/^"\(.*\)"$/\1/')
    dir=$(dirname "$file")
    # Skip if file lives inside a nested git repo (stow package with its own .git)
    if git -C "$dir" rev-parse --git-dir &>/dev/null 2>&1; then
        nested_root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
        our_root=$(git rev-parse --show-toplevel 2>/dev/null)
        if [ "$nested_root" != "$our_root" ]; then
            continue
        fi
    fi
    GIT_STATUS+="$line"$'\n'
done <<< "$GIT_STATUS_RAW"
GIT_STATUS="${GIT_STATUS%$'\n'}"

unpushed=$(git log "origin/$branch..HEAD" --oneline 2>/dev/null || true)

if [ -z "$GIT_STATUS" ] && [ -z "$unpushed" ]; then
    echo "Nothing to commit or push."
    exit 0
fi

if [ -z "$GIT_STATUS" ] && [ -n "$unpushed" ]; then
    echo "Unpushed commits:"
    echo "$unpushed"
    read -rp "Push to '$branch'? (Y/n): " confirm
    confirm="${confirm:-Y}"
    [[ "$confirm" =~ ^[Yy]$ ]] && git push origin "$branch" && echo "Pushed." || echo "Push cancelled."
    exit 0
fi

# --- Collect diffs & run AI 
echo ""
echo "Collecting diffs..."
all_diffs=$(collect_changes "$GIT_STATUS")

echo "Running AI inference${GPU_TYPE:+ on $GPU_TYPE} (one pass for all files)..."
ai_output=$(generate_ai_messages_batch "$all_diffs" || true)

ai_line_count=$(echo "$ai_output" | grep -c "|||" 2>/dev/null || true)
ai_line_count="${ai_line_count:-0}"
if [ "${ai_line_count}" -eq 0 ] 2>/dev/null || [ -z "$ai_line_count" ]; then
    echo "  WARNING: AI produced no output — using rule-based fallback for all files."
else
    echo "  AI generated $ai_line_count message(s)"
fi

# --- Build filepath -> message lookup 
declare -A ai_messages
while IFS= read -r line; do
    if [[ "$line" == *"|||"* ]]; then
        local_path="${line%%|||*}"
        local_msg="${line##*|||}"
        local_path=$(echo "$local_path" | xargs)
        local_msg=$(echo "$local_msg" | xargs)
        [ -n "$local_path" ] && [ -n "$local_msg" ] && ai_messages["$local_path"]="$local_msg"
    fi
done <<< "$ai_output"

# --- Stage and commit each file individually 
commit_counter=0
echo ""

while IFS= read -r line; do
    [ -z "$line" ] && continue
    status=$(echo "$line" | awk '{print $1}')
    file=$(echo "$line" | awk '{print substr($0, index($0,$2))}' | sed 's/^ *//; s/^"\(.*\)"$/\1/')

    commit_msg="${ai_messages[$file]:-}"
    if [ -z "$commit_msg" ] || [[ ${#commit_msg} -lt 10 ]] || [[ "$commit_msg" == *"<|"* ]]; then
        commit_msg=$(rule_based_message "$file" "$status")
        label="[fallback]"
    else
        label="[AI]      "
    fi

    echo "  $label $file"
    echo "           -> $commit_msg"

    # Unstage everything first so each commit only contains one file
    git reset HEAD -- . &>/dev/null || true

    case "$status" in
        D)    git rm --ignore-unmatch -- "$file" &>/dev/null || true ;;
        A|??) git add -- "$file" ;;
        M|MM) git add -- "$file" ;;
        R*)   git add -- "$file" ;;
        *)    echo "  Skipping unknown status '$status' for $file"; continue ;;
    esac

    # Skip if nothing actually staged (e.g. deleted file already gone)
    if git diff --cached --quiet 2>/dev/null; then
        echo "  Nothing staged for $file — skipping"
        continue
    fi

    if git commit -m "$commit_msg" 2>/dev/null; then
        commit_counter=$((commit_counter + 1))
    else
        echo "  Commit failed for $file"
    fi

done <<< "$GIT_STATUS"

# --- Push 
echo ""
if [ "$commit_counter" -eq 0 ]; then
    echo "No commits made."
else
    echo "$commit_counter commit(s) made."
    read -rp "Push to '$branch'? (Y/n): " confirm_push
    confirm_push="${confirm_push:-Y}"
    if [[ "$confirm_push" =~ ^[Yy]$ ]]; then
        git push origin "$branch" && echo "Pushed to '$branch'." || echo "Push failed."
    else
        echo "Push cancelled. Commits are local."
    fi
fi