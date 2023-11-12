declare-user-mode git
map global git n ':git next-hunk<ret>' -docstring 'goto next hunk'
map global git p ':git prev-hunk<ret>' -docstring 'goto previous hunk'

# Main hook (git branch update, gutters)
declare-option str git_branch_name
hook global -group git-main-hook NormalIdle .* %{
  # Update git diff column signs
  try %{ git update-diff }

  # Update branch name
  set-option global git_branch_name %sh{ git rev-parse --is-inside-work-tree &> /dev/null && echo " $(git rev-parse --abbrev-ref HEAD)"}
}

## Blame current line
set-face global git_current_line_hash green,black
set-face global git_current_line_author default,black@ts_keyword
set-face global git_current_line_date default,black@comment

define-command git-blame-current-line %{
  info -markup -style above -anchor "%val{cursor_line}.%val{cursor_column}" -- %sh{git blame -L$kak_cursor_line,$kak_cursor_line $kak_bufname | sed -rn 's/^([a-f0-9]+) \((.*) ([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]).*\).*$/{git_current_line_hash}\1 {git_current_line_author}\2 {git_current_line_date}\3/p'}
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
