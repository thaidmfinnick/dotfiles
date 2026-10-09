# s: fuzzy-pick a Host from ~/.ssh/config (and its Includes) and ssh to it.
# `s foo` pre-fills the query and connects directly if only one host matches.
_ssh_hosts() {
  local -a files queue
  local f line
  queue=(~/.ssh/config)
  while (( $#queue )); do
    f=${queue[1]}; shift queue
    [[ -r $f ]] || continue
    files+=$f
    for line in ${(f)"$(grep -iE '^[[:space:]]*Include[[:space:]]' $f)"}; do
      for f in ${(z)line#*[Ii]nclude}; do
        [[ $f != /* && $f != \~* ]] && f=~/.ssh/$f
        queue+=(${~f}(N))
      done
    done
  done
  awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) if ($i !~ /[*?!]/) print $i }' $files | awk '!seen[$0]++'
}

s() {
  local host
  host=$(_ssh_hosts | fzf --height=40% --reverse --prompt='ssh> ' \
    --query="$*" --select-1 --exit-0 \
    --preview='ssh -G {} | grep -E "^(hostname|user|port|identityfile|proxyjump) "' \
    --preview-window=right,50%) || return
  print -s "ssh $host"
  ssh $host
}
