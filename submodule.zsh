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
        git difftool || true
    fi
    if git config --get remote.origin.url | grep 'antiqueeverett'; then
        git difftool || true
    fi
    '
    subpush
}

function subpush () {
    git submodule foreach --recursive '
    if git config --get remote.origin.url | grep 'edisonslightbulbs'; then
        git push || true
    fi
    if git config --get remote.origin.url | grep 'antiqueeverett'; then
        git push || true
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

function substat() {
    git submodule foreach --recursive '
    if git config --get remote.origin.url | grep 'edisonslightbulbs'; then
        git status
    fi
    if git config --get remote.origin.url | grep 'antiqueeverett'; then
        git status
    fi
    '
}

# subrm
#   Removes a submodule the right way.
function subrm() {
    git submodule deinit -f "$@"
    git rm -rf "$@"
    # Note: asubmodule (no trailing slash)
    # or, if you want to leave it in your working tree
    # git rm --cached <asubmodule>
    # rm -rf .git/modules/<asubmodule>
}
