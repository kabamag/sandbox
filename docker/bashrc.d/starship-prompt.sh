# Starship-Prompt fuer interaktive bash-Shells.
# Wird von /etc/bash.bashrc und ~/.bashrc als letzte Prompt-Anpassung geladen,
# damit der statische PS1-Fallback weiter unten nicht gewinnt. Fehlt das Binary
# (INSTALL_STARSHIP=false), bleibt der bisherige Prompt unveraendert.
if [ -n "${BASH_VERSION:-}" ] && [ -t 1 ] && command -v starship >/dev/null 2>&1; then
  if ! declare -F starship_precmd >/dev/null 2>&1; then
    eval "$(starship init bash)"
  fi
fi
