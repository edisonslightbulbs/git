#!/bin/zsh

# .submodule.zsh:
#   Extended submodule operations.
# author: Everett
# created: 2021-03-25 08:10
# Github: https://github.com/antiqueeverett/


# clone
#    For a repo with submodules, clone recursively
function clone() {
    shift
    command git clone --recursive "$*" -j8
}


# pull
#   For a repo with submodules, auto-recursive pull
function pull() {
    local CURR_DIR="$PWD"

    # iff repo has submodules ...
    if test -f '.gitmodules'; then
        if grep -w -q 'submodule' '.gitmodules'; then
            # pull in all submodule changes
            command git pull --recurse-submodules -j 8
            git submodule update --init --recursive -j 8
            #git submodule update --init --recursive --remote --rebase -j 8
        fi
    else
        command git pull -j 8
    fi
    cd "$CURR_DIR" || return # retain working directory
}

function subadd () {
    command git submodule add "$@"
}

function subcommit () {
    git submodule foreach --recursive '
    if git config --get remote.origin.url | grep 'edisonslightbulbs'; then
        git difftool
    fi
    if git config --get remote.origin.url | grep 'antiqueeverett'; then
        git difftool
    fi
    '
}

function subpush () {
    git submodule foreach --recursive '
    if git config --get remote.origin.url | grep 'edisonslightbulbs'; then
        git push
    fi
    if git config --get remote.origin.url | grep 'antiqueeverett'; then
        git push
    fi
    '
}

# sublst
#   Lists current repository submodules.
function sublst() {
    git config --file .gitmodules --get-regexp path | awk '{ print $2 }'
}


function subupdate() {
    git submodule foreach --recursive '
    if git config --get remote.origin.url | grep 'edisonslightbulbs'; then
        git checkout main || git checkout master ||  true
        git pull origin main || git checkout master || true
    fi
    if git config --get remote.origin.url | grep 'antiqueeverett'; then
        git checkout main || git checkout master ||  true
        git pull origin main || git checkout master || true
    fi
    '
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
    #  [ -print0 ] and [ -0 ]. Also, use [ -r ] to
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
            # i) deregister submodule path
            if ! git submodule deinit -f -- "$MODULE"; then
                echo "Something went wrong: unable to unregister submodule path"
            else
                # ii) remove submodule
                if ! git rm -f "$MODULE"; then
                    echo "Something went wrong: unable to remove submodule from git repository"
                else
                    # iii) remove submodule from .git/modules
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
