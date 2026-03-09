#!/bin/bash

# --- AI BOOTSTRAP START ---
# (Added to ensure the AI works wherever you run this)
CACHE_DIR="$HOME/.cache/ai-committer"
MODEL_URL="https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
MODEL_PATH="$CACHE_DIR/llama-3b-instruct.gguf"

OS_TYPE=$(uname -s)
if [[ "$OS_TYPE" == *"MINGW"* || "$OS_TYPE" == *"MSYS"* || "$OS_TYPE" == *"CYGWIN"* ]]; then
	OS="windows"
	BIN_NAME="llama-cli.exe"
elif [[ "$OS_TYPE" == "Darwin" ]]; then
	OS="mac"
	BIN_NAME="llama-cli"
else
	OS="linux"
	BIN_NAME="llama-cli"
fi
BIN_PATH="$CACHE_DIR/$BIN_NAME"

mkdir -p "$CACHE_DIR"

if [ ! -f "$BIN_PATH" ]; then
	echo "Downloading AI engine..."
	if [[ "$OS" == "windows" ]]; then
		URL="https://github.com/ggerganov/llama.cpp/releases/download/b4400/llama-b4400-bin-win-avx2-x64.zip"
	elif [[ "$OS" == "mac" ]]; then
		URL="https://github.com/ggerganov/llama.cpp/releases/download/b4400/llama-b4400-bin-macos-arm64.zip"
	else
		URL="https://github.com/ggerganov/llama.cpp/releases/download/b4400/llama-b4400-bin-ubuntu-x64.zip"
	fi
	curl -L "$URL" -o "$CACHE_DIR/bin.zip"
	unzip -j "$CACHE_DIR/bin.zip" "**/$BIN_NAME" -d "$CACHE_DIR"
	[ "$OS" != "windows" ] && chmod +x "$BIN_PATH"
	rm "$CACHE_DIR/bin.zip"
fi

if [ ! -f "$MODEL_PATH" ]; then
	echo "Downloading Intelligent AI Model (~2.0GB)..."
	curl -L "$MODEL_URL" -o "$MODEL_PATH"
fi

# AI Function to replace generic messages
generate_ai_message() {
	local file=$1
	local status=$2
	local diff_context=""

	if [[ "$status" == "D" ]]; then
		diff_context="[DELETED] The file $file was deleted."
	elif [[ "$status" == "??" || "$status" == "A" ]]; then
		diff_context="[NEW FILE] Content of $file:\n$(head -n 50 "$file" 2>/dev/null | tr -d '\r')"
	else
		diff_context="[MODIFIED] Changes in $file:\n$(git diff HEAD -- "$file" 2>/dev/null | tail -c 2000 | tr -d '\r')"
	fi

	local prompt="<|begin_of_text|><|start_header_id|>system<|end_header_id|>
You are a senior engineer. Write a professional, human-like 1-line git commit message.
RULES:
1. Use Conventional Commits (feat, fix, docs, refactor).
2. Do not use quotes or markdown.
3. Be specific about the change.
4. Output ONLY the message.<|eot_id|><|start_header_id|>user<|end_header_id|>
$diff_context<|eot_id|><|start_header_id|>assistant<|end_header_id|>"

	local result=$("$BIN_PATH" -m "$MODEL_PATH" -p "$prompt" -n 60 --no-display-prompt --temp 0.2 2>/dev/null)
	echo "$result" | sed 's/<|eot_id|>//g; s/assistant://g; s/\[end of text\]//g' | tr -d '"' | xargs
}
# --- AI BOOTSTRAP END ---

# Prompt for the repository path
read -p "Enter the Git repository path: " repo_path

# Check if the path exists and is a valid Git repository
if [ ! -d "$repo_path/.git" ]; then
	echo "The specified path is not a Git repository. Please provide a valid repo path."
	exit 1
fi

# Change to the repository directory
cd "$repo_path" || exit

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Prompt for the branch to push changes to
read -p "Enter branch to push changes (default: $current_branch): " input_branch
branch=${input_branch:-$current_branch}

# Check for unstaged changes
changes=$(git status --porcelain)
unpushed_changes=$(git log origin/"$branch"..HEAD --oneline 2>/dev/null)

if [ -z "$changes" ] && [ -z "$unpushed_changes" ]; then
	echo "No changes detected. Exiting."
	exit 0
fi

# If there are committed but unpushed changes
if [ -z "$changes" ] && [ -n "$unpushed_changes" ]; then
	echo "You have unpushed commits:"
	echo "$unpushed_changes"
	read -p "Do you want to push these commits to branch '$branch'? (Y/n): " confirm_push
	confirm_push=${confirm_push:-Y} # Default to "Y" if input is blank
	if [[ "$confirm_push" =~ ^[Yy]$ ]]; then
		echo "Pushing changes to branch '$branch'..."
		git push origin "$branch" && echo "Changes have been pushed to the remote repository." || echo "Push failed. Check your connection or permissions."
	else
		echo "Push cancelled. Changes remain committed locally."
	fi
	exit 0
fi

# Initialize commit counter
commit_counter=0

# Loop through each change and commit individually
echo "Processing changes with AI..."
while IFS= read -r line; do
	# Extract status and file name, handling spaces correctly
	status=$(echo "$line" | awk '{print $1}')
	file=$(echo "$line" | awk '{print substr($0, index($0,$2))}' | sed 's/^ *//')

	# Debugging: Output the status and file to ensure correct handling
	echo "Analyzing file: \"$file\" with status: $status"

	# Remove any unwanted quotes around the file name
	file=$(echo "$file" | sed 's/^"\(.*\)"$/\1/')

	# Check if the file or directory exists
	if [ ! -e "$file" ] && [ "$status" != "D" ]; then
		echo "Warning: File or directory $file does not exist."
		continue
	fi

	# Determine commit message based on file status (Now using AI)
	case "$status" in
	"A" | "??") # Added or Untracked
		git add -- "$file"
		commit_message=$(generate_ai_message "$file" "$status")
		;;
	"M") # Modified files
		git add -- "$file"
		commit_message=$(generate_ai_message "$file" "$status")
		;;
	"D") # Deleted files
		commit_message=$(generate_ai_message "$file" "$status")
		git rm --ignore-unmatch "$file"
		;;
	*) # Other statuses
		echo "Unknown status: $status for file: $file. Skipping."
		continue
		;;
	esac

	# Commit the change
	echo "Committing: \"$commit_message\""
	git commit -m "$commit_message" && commit_counter=$((commit_counter + 1)) || {
		echo "Commit failed for file: $file"
		continue
	}

done <<<"$(git status --porcelain)"

# Check if there were no commits
if [ "$commit_counter" -eq 0 ]; then
	echo "No new changes to commit."
else
	echo "$commit_counter commit(s) have been successfully made."
fi

# Confirm pushing the changes
read -p "Do you want to push all changes to branch '$branch'? (Y/n): " confirm_push
confirm_push=${confirm_push:-Y} # Default to "Y" if input is blank
if [[ "$confirm_push" =~ ^[Yy]$ ]]; then
	echo "Pushing changes to branch '$branch'..."
	git push origin "$branch" && echo "Changes have been pushed to the remote repository." || echo "Push failed. Check your connection or permissions."
else
	echo "Push cancelled. Changes remain committed locally."
fi
