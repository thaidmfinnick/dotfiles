#!/usr/bin/env bash
# Checkbox menu in plain bash (Git Bash has no dialog/whiptail).
#   MENU_LABELS=(...) MENU_SEL=(1 0 ...)   # SEL = preselected
#   checklist "Title"                      # fills MENU_SEL with the final choice
# Keys: up/down or j/k move, space toggles, a all, n none, enter confirm, q quit.

checklist() {
  local title="$1" n=${#MENU_LABELS[@]} cur=0 i key rest mark drawn=0
  local top=0 page=$(( $(tput lines 2>/dev/null || echo 24) - 5 ))
  (( page < 5 )) && page=5
  (( page > n )) && page=$n

  # No terminal to ask on: keep the defaults
  [[ -t 0 && -t 1 ]] || return 0

  printf '\033[?25l'
  trap 'printf "\033[?25h"' RETURN

  while true; do
    (( drawn )) && printf '\033[%dA' $(( page + 2 ))
    drawn=1
    (( cur < top )) && top=$cur
    (( cur >= top + page )) && top=$(( cur - page + 1 ))
    printf '\033[2K\033[1m%s\033[0m  (space toggle, a all, n none, enter confirm, q quit)\n' "$title"
    for (( i = top; i < top + page; i++ )); do
      mark=' '; (( MENU_SEL[i] )) && mark='x'
      if (( i == cur )); then
        printf '\033[2K\033[36m> [%s] %s\033[0m\n' "$mark" "${MENU_LABELS[i]}"
      else
        printf '\033[2K  [%s] %s\n' "$mark" "${MENU_LABELS[i]}"
      fi
    done
    printf '\033[2K\033[2m%d of %d selected\033[0m\n' "$(printf '%s\n' "${MENU_SEL[@]}" | grep -c 1)" "$n"

    IFS= read -rsn1 key
    if [[ $key == $'\033' ]]; then read -rsn2 -t 1 rest || true; key+="$rest"; fi
    case "$key" in
      $'\033[A'|k) (( cur > 0 )) && cur=$(( cur - 1 )) ;;
      $'\033[B'|j) (( cur < n - 1 )) && cur=$(( cur + 1 )) ;;
      ' ') MENU_SEL[cur]=$(( 1 - MENU_SEL[cur] )) ;;
      a) for (( i = 0; i < n; i++ )); do MENU_SEL[i]=1; done ;;
      n) for (( i = 0; i < n; i++ )); do MENU_SEL[i]=0; done ;;
      '') return 0 ;;
      q) for (( i = 0; i < n; i++ )); do MENU_SEL[i]=0; done; return 0 ;;
    esac
  done
}
