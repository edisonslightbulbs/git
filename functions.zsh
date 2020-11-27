#!/bin/zsh

# functions.zsh:
#   Functions for custom git aliases.
# author: Everett
# created: 2020-11-04 08:50
# Github: https://github.com/antiqueeverett/

# mv: [ tested ]
#   Helps out with correctly moving files,
#   i.e., using git mv iff mv is used inside
#   a git repository.
function mv() {
    # $(command) syntax produces a single variable to be passed as argument
    # if ( .... ) wraps conditional in a sub shell to redirect output
    if ( [ $(git rev-parse --git-dir) ] && [ $(git ls-files "$@") ] ) > /dev/null 2>&1 ; then
		git mv "$@"
	else
		command mv "$@"
	fi
}

# attach: [ tested ]
#  Attaches a detached head to the main branch.
function attach() {
	shift
	# check for unstage changes
	if git diff-files --quiet --ignore-submodules --; then
		# check for uncommitted changes
		if git diff-index --quiet HEAD --; then # if after commit
			# create a new temp branch
			if git show-ref --verify --quiet refs/heads/temp; then
				git branch -d temp
			else
				git checkout -b temp
			fi
			# force $1 branch to start from temp head
			git branch -f $1 temp
			git checkout $1
			# delete temp branch
			git branch -d temp
		else
			echo "Commit changes before attaching head"
		fi
	else
		echo "Stage changes, and commit them first"
	fi
}

# sublst:  [ tested ]
#   Lists current repository submodules.
function sublst() {
	git config --file .gitmodules --get-regexp path | awk '{ print $2 }'
}

# clone: [ tested ]
#    For a repo with submodules, clone recursively
function clone() {
	shift
	command git clone --recursive "$*" -j8
}

# diff: [ tested ]
#   Always shows a relative, most recent diff, i.e., shows
#     : diff iff un-staged, else -> diff iff staged, else -> diff iff committed
function diff() {
	if ! git diff-files --quiet --ignore-submodules --; then
		command git diff
		return
	elif [[ -n $(git status --porcelain) ]]; then
		command git diff --cached
		return
	else
		command git diff HEAD^ HEAD
	fi
}

# pull: [ tested ]
#   For a repo with submodules, auto-recursive pull
function pull() {
	local CURR_DIR="$PWD"

	# iff repo has submodules ...
	if test -f '.gitmodules'; then
		if grep -w -q 'submodule' '.gitmodules'; then
			# pull in all submodule changes
			command git pull --recurse-submodules -j 8
			git submodule update --init --recursive -j 8
		fi
	else
		command git pull -j 8
	fi
	cd "$CURR_DIR" || return # retain working directory
}

# root: [ tested ]
#   Navigates to a git root directory.
function root() {
	local ROOT
	ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo -n .)"

	if [ $# -eq 0 ]; then
		cd "$ROOT" || return
	fi
}

# sr: [ tested ]
#   Removes a submodule, correctly.
function subrm() {
	shift
	echo "$1"
	local ROOT
	ROOT="$PWD"

	#  find the absolute path of a submodule iff it exists:
	#   to allow for non-alphanumeric filenames change from using [ -print0 ] and [ -0 ]
	#   while read [ -r ] prevents mangling of back slashes
	find . -type d -name "$1" -print0 | xargs -0 realpath | while read -r MODULEPATH; do
		cd "$MODULEPATH" || return

		# use the .git *file to ID the submodule
		if test -f '.git'; then
			# todo: optimize find strategy by grepping the .git file
			echo "Found submodule: $1"
			echo "Removing submodule: $1"

			# strip-off leading absolute path
			MODULE=${MODULEPATH#"$ROOT"/}
			echo "$MODULE"

			cd "$ROOT" || return

			# correctly remove git submodule
			# i. deregister submodule path
			if ! git submodule deinit -f -- "$MODULE"; then
				echo "Something went wrong: unable to unregister submodule path"
			else
				# ii. remove submodule
				if ! git rm -f "$MODULE"; then
					echo "Something went wrong: unable to remove submodule from git repository"
				else
					# iii. remove submodule from .git/modules
					if ! rm -rf .git/modules/"$MODULE"; then
						echo "Something went wrong: unable delete submodule from git module path"
					else
						echo "Submodule removed from project repository successfully"
						return
					fi
				fi
			fi
		fi
	done
}

# # state():
# #    Recursively checks the state of parent-child repos
# function state(){
#     if [ -f .git ] || [ -d .git ]; then
#         # iff repo is dirty, let me know
#         if [[ $(git diff --stat) != '' ]]; then
#
#             # get repo name
#             printf '%s\n' "${PWD##*/}" || basename "$(git rev-parse --show-toplevel)"
#
#             # check state
#             command git diff --quiet || echo " -- dirty \n"
#
#             return
#         else
#             # ... else let me know its clean
#             printf '%s\n' "${PWD##*/}"
#             [[ -n $(git status -s) ]] || echo " -- clean \n"
#         fi
#     fi
# }
