# ---- FZF -----
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# -- Use fd instead of fzf --
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND --type=f"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Catppuccin Macchiato palette, shared by all fzf pickers.
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }\
--color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
--color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 \
--color=selected-bg:#494d64,border:#6e738d,label:#cad3f5"

export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

export FZF_CTRL_T_OPTS="--style full \
--bind 'enter:execute-silent(for file in {+}; do
  if root=\$(git -C \"\$(dirname -- \"\$file\")\" rev-parse --show-toplevel 2>/dev/null); then
    \${EDITOR:-code} -- \"\$root\" \"\$file\"
  else
    \${EDITOR:-code} -- \"\$file\"
  fi
done)+abort' \
--preview 'bat -n \
--color=always \
--line-range :500 {}' \
--border sharp \
--layout reverse \
--prompt '∷ ' \
--pointer ▶ \
--marker ⇒"

# ---- Yazi -----
# Shell wrapper for yazi to change directory after selection
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
