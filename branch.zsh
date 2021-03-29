#!/bin/zsh

# .branch.zsh:
#   Extended branch operations.
# author: Everett
# created: 2021-03-25 08:10
# Github: https://github.com/antiqueeverett/


# root
#   Navigates to a git root directory.
function root() {
    local ROOT
    ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo -n .)"

    if [ $# -eq 0 ]; then
        cd "$ROOT" || return
    fi
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


# brmk [ beta ]
#   Creates a new branch (local and remote !).
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



# git branch | fzf | xargs git checkout
