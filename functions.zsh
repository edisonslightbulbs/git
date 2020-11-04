#!/bin/zsh

# functions.zsh:
#   Functions for custom git aliases.
# author: Everett
# created: 2020-11-04 08:50
# Github: https://github.com/antiqueeverett/


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
    ROOT="$(git rev-parse --show-toplevel 2> /dev/null  || echo -n .)"

    if [ $# -eq 0 ]; then
        cd "$ROOT" || return
    fi
}


# sr: [ tested ]
#   Removes a submodule, correctly.
function sr() {
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


# attach():
#   Attaches a detached head to the main branch.
#
# TODO:
#   In principle, this should be dynamic, i.e., one should be
#   able to pass the branch to force the detached head onto.
#
# USE CASE:
#   i. After submodule update
#
# function attach() {
#     # check for any uncommitted changes
#     if [ -n "$(git status --porcelain)" ]; then
#         echo "Please commit changes before attaching head to main branch";
#     else
#         # create temp branch
#         if [ `git branch --list temp` ]; then
#             command git branch -d temp
#         else
#             command git checkout -b temp
#         fi
#         command git -f master temp || git -f main temp
#         command git checkout master
#         command git branch -d temp
#     fi
# }
#
#
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
#
#
#
# # global():
# #   Global state of all repositories
# #
# function global() {
#     local CURR_DIR="$PWD"
#
#     # find and check the state of all submodules (depth = 3)
#     for DIR in $(find "$HOME/Repositories" -maxdepth 3 -mindepth 1 -type d); do
#         cd "$DIR" || return
#         state
#     done
#     cd "$CURR_DIRR" || return
# }
#
# # sl():
# #   Lists submodules
# #
# function sl() {
#     command git config --file .gitmodules --get-regexp path | awk '{ print $2 }'
# }
#
# # subrm():
# #   Removes selected submodule
# #
# function subrm() {
#     command git submodule deinit -f -- "$1"
#     rm -rf .git/modules/"$1"
#     command git rm -f "$1"
# }
#
#
#
# # GIT FUNCTIONS (corner cases tested) : ---------------------------------------
#
#
# # diff():
# #   Shows most recent diff.
# function diff() {
#     if  git diff-index --quiet HEAD --; then # if after commit
#         command git diff HEAD^ HEAD
#     else
#         if command git diff --cached --exit-code; then # if after state
#             command git diff
#         else
#             command git diff --cached # if after change
#         fi
#     fi
# }
#
# # comm():
# #    Allows for commit messages without wrapping quotes.
# function comm() {
#     shift
#     command git commit -m "$*"
# }
#
# # commit():
# #    Default clone to recursive clone strategy.
# function clone(){
#     shift
#     command git clone --recursive "$*" -j8
# }
#
#
# # git():
# #   This function makes it possible to alias the functions given above, i.e.,
# #                               git <alias>
# #                            =  git <function>
# #
# #   E.g., git root # changes to root git directory.
# function git () {
#     if [ "$1" = "root" ]; then
#         root
#         # elif [ "$1" = "pull" ]; then
#         #     pull
#         # elif [ "$1" = "clone" ]; then
#         #     clone "$@"
#         # elif [ "$1" = "push" ]; then
#         #     push
#         #    elif [ "$1" = "subrm" ]; then
#         #        shift
#         #        subrm "$1"
#         #elif [ "$1" = "diff" ]; then
#         #    diff
#         # elif [ "$1" = "global" ]; then
#         #     global
#         # elif [ "$1" = "comm" ]; then
#         #     comm "$@"
#         # elif [ "$1" = "attach" ]; then
#         #     attach
#         # elif [ "$1" = "sl" ]; then
#         #     sl
#         else
#         command git "$@"
#     fi
# }
