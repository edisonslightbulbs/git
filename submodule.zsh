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
    command git clone --recursive -j 8 "$*"
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
    subpush
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


function subpull() {
    git submodule foreach --recursive '
    if git config --get remote.origin.url | grep 'edisonslightbulbs'; then
        git checkout main || git checkout master ||  true
        git pull origin main || git pull origin master || true
    fi
    if git config --get remote.origin.url | grep 'antiqueeverett'; then
        git checkout main || git checkout master ||  true
        git pull origin main || git pull origin master || true
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
