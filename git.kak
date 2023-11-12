declare-option str git_branch_name
declare-option str awk_cmd 'awk'

declare-user-mode git
map global git n ':git next-hunk<ret>' -docstring 'goto next hunk'
map global git p ':git prev-hunk<ret>' -docstring 'goto previous hunk'

# Main hook (git branch update, gutters)
hook global -group git-main-hook NormalIdle .* %{
  # Update git diff column signs
  try %{ git update-diff }

  # Update branch name
  set-option global git_branch_name %sh{ git rev-parse --is-inside-work-tree &> /dev/null && echo " $(git rev-parse --abbrev-ref HEAD)"}
}

## Blame current line
set-face global GitBlameLineRef red,black
set-face global GitBlameLineSummary green,black
set-face global GitBlameLineAuthor blue,black
set-face global GitBlameLineTime default,black@comment

#define-command git-blame-current-line %{
#  info -markup -style above -anchor "%val{cursor_line}.%val{cursor_column}" -- %sh{git blame -L$kak_cursor_line,$kak_cursor_line $kak_bufname | sed -rn 's/^([^ ]+) \((.*) ([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]).*\).*$/{git_current_line_hash}\1 {git_current_line_author}\2 {git_current_line_date}\3/p'}
#}

define-command git-blame-current-line %{
  info -markup -style above -anchor "%val{cursor_line}.%val{cursor_column}" -- %sh{
    git blame -L$kak_cursor_line,$kak_cursor_line $kak_bufname --incremental | gawk '\
BEGIN {
  ref = ""
  author = ""
  time = ""
  summary = ""
}

/^[a-f0-9]+ [0-9]+ [0-9]+ [0-9]+$/ {
  ref = substr($1, 0, 8)
}

/summary/ {
  for (i = 2; i < NF; i++) {
    summary = summary $i " "
  }

  summary = summary $NF
}

/author / {
  for (i = 2; i < NF; i++) {
    author = author $i " "
  }

  author = author $NF
}

/author-time/ {
  time = strftime("%a %b %Y, %H:%M:%S", $2)
}

END {
  printf "{GitBlameLineRef}%s {GitBlameLineSummary}%s\n", ref, summary
  printf "{GitBlameLineAuthor}%s {GitBlameLineTime}on %s", author, time
}'
  }
}

map global git b ':git-blame-current-line<ret>' -docstring 'blame current line'

## Show the commit that touched the line under the cursor.
declare-option str git_show_current_line_commit
define-command git-show-current-line %{
  set-option global git_show_current_line_commit %sh{ git blame -L$kak_cursor_line,$kak_cursor_line $kak_bufname | cut -d' ' -f1 }
  edit -scratch *git*
  set-option buffer filetype git-commit
  set-option buffer kts_lang git-commit
  execute-keys '%|git show --pretty=fuller $kak_opt_git_show_current_line_commit<ret>gg'
  set-option buffer readonly true
}

map global git <ret> ':git-show-current-line<ret>' -docstring 'open last commit that touched current line'
