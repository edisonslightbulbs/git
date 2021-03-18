#!/bin/zsh

# functions.zsh:
#   Functions for custom git aliases.
# author: Everett
# created: 2020-11-04 08:50
# Github: https://github.com/antiqueeverett/

# brmk [ beta dev ]
#   Creates a new branch (local-remote).
function brmk() {
    shift
    local remote=$1
    local branchname=$2
    git checkout -b $branchname
    git push $remote $branchname
    git push $remote $branchname
    git push origin -u $branchname
}

# brm [ beta dev ]
#    Renames a local and remote branch.
#    Caveat:
#      This operation should be carried out outside the
#      branch of interest, i.e., from a different branch
function brm() {
    shift
    local newname=$1
    local oldname=$2
    git branch -m $oldname $newname
    git push origin:$oldname $newname
    git push origin -u $newname
}


# mv
#   Enforces moving svn files correctly; that is,
#   uses [ git mv ] command iff [ mv ] command is
#   accidentally used within a git repository.
function mv() {
    # verify we are in a git repo
    if ( [ $(git rev-parse --git-dir) ] && [ $(git ls-files "$@") ] ) > /dev/null 2>&1 ; then
        git mv "$@"
    else
        command mv "$@"
    fi
}
# syntax notes:
#  - $(command) produces a single variable to be passed as an argument
#  - if ( .... ) wraps conditional in a sub shell to redirect output


# attach
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

# sublst
#   Lists current repository submodules.
function sublst() {
    git config --file .gitmodules --get-regexp path | awk '{ print $2 }'
}

# clone
#    For a repo with submodules, clone recursively
function clone() {
    shift
    command git clone --recursive "$*" -j8
}

# diff
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

# pull
#   For a repo with submodules, auto-recursive pull
function pull() {
    local CURR_DIR="$PWD"

    # iff repo has submodules ...
    if test -f '.gitmodules'; then
        if grep -w -q 'submodule' '.gitmodules'; then
            # pull in all submodule changes
            git submodule update --init --recursive -j 10
            git submodule update --recursive --remote -j 10
        fi
    else
        command git pull -j 8
    fi
    cd "$CURR_DIR" || return # retain working directory
}

# root
#   Navigates to a git root directory.
function root() {
    local ROOT
    ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo -n .)"

    if [ $# -eq 0 ]; then
        cd "$ROOT" || return
    fi
}

# subco
#   Checks out all submodules.
function subco() {
    git submodule foreach --recursive git checkout main || git checkout master -j 10
    git submodule foreach --recursive command git pull  -j 10
}

# subrm
#   Removes a submodule the right way.
function subrm() {
    shift
    echo "$1"
    local ROOT
    ROOT="$PWD"

    #  In finding the absolute path of a submodule,
    #  allow for non-alphanumeric filenames using
    #  [ -print0 ] and [ -0 ]. Also use [ -r ] to
    #  prevents mangling of back slashes
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
