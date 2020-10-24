#!/bin/sh
#
# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/tighten/paddles/main/tools/install.sh)"
# or via wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/tighten/paddles/main/tools/install.sh)"
# or via fetch:
#   sh -c "$(fetch -o - https://raw.githubusercontent.com/tighten/paddles/main/tools/install.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/tighten/paddles/main/tools/install.sh
#   sh install.sh

set -e

BIN=/usr/local/bin

get_os() {
    local unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)     OS=linux;;
        Darwin*)    OS=macos;;
        *)          OS="UNKNOWN:${unameOut}"
    esac
}

# https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh#L52
command_exists() {
    command -v "$@" >/dev/null 2>&1
}

composer_required() {
    # @todo Can we check this?
    echo ""
}

# https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh#L60
underline() {
	echo "$(printf '\033[4m')$@$(printf '\033[24m')"
}

# https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh#L52
setup_color() {
	# Only use colors if connected to a terminal
	if [ -t 1 ]; then
		RED=$(printf '\033[31m')
		GREEN=$(printf '\033[32m')
		YELLOW=$(printf '\033[33m')
		BLUE=$(printf '\033[34m')
		BOLD=$(printf '\033[1m')
		RESET=$(printf '\033[m')
	else
		RED=""
		GREEN=""
		YELLOW=""
		BLUE=""
		BOLD=""
		RESET=""
	fi
}

title() {
    local TITLE=$@
    echo ""
    echo "${BOLD}${TITLE}${RESET}"
    echo "============================================================"
}

setup_php() {
    title "Installing PHP..."

    if command_exists php; then
        echo "We'll rely on your built-in PHP for now."
    else
        echo "Sorry, only programmed for built-in PHP so far."
        exit
    fi
}

# https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
setup_composer() {
    title "Installing Composer..."

    if command_exists composer; then
        echo "Composer already installed; skipping."
    else
        echo "Downloading Composer..."
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

        if command_exists curl; then
            echo "Checking validity of the downloaded file..."

            local EXPECTED_CHECKSUM="$(curl -fsSL https://composer.github.io/installer.sig)"
            local ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

            if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
            then
                >&2 echo 'ERROR: Invalid installer checksum from Composer'
                rm composer-setup.php
                exit 1
            fi
        else
            echo "Can't check Composer's signature because your machine doesn't have curl."
        fi

        echo "Running Composer setup script..."
        php composer-setup.php --quiet
        RESULT=$?
        rm composer-setup.php

        local TARGET_PATH="$BIN/composer"
        mv composer.phar $TARGET_PATH

        if [ $RESULT ]; then
            echo "Composer installed!"
        else
            echo "Error installing Composer."
            exit
        fi
    fi
}

composer_has_package() {
    composer global show 2>/dev/null | grep "$@" >/dev/null
}

composer_require() {
    if composer_has_package "$@"; then
        echo "$@ already installed; skipping."
    else
        echo "Installing $@..."
        composer global require "$@"
    fi
}

setup_laravel_installer() {
    title "Installing the Laravel Installer..."
    composer_require laravel/installer
}

setup_takeout() {
    title "Installing Takeout..."
    composer_require tightenco/takeout
}

instructions() {
    echo ""
    echo "In order for Takeout to work, you'll want to set up Docker."
    echo "Here are instructions for your system:"
    echo ""
    underline "https://takeout.tighten.co/install/$OS"
    echo ""
}

main() {
    get_os

    setup_color

    setup_php
    setup_composer
    setup_laravel_installer
    setup_takeout

    echo ""
    echo ""
    echo ""
    printf "$BLUE"
	cat <<-'EOF'
                    __      __   ___
                   /\ \    /\ \ /\_ \
 _____      __     \_\ \   \_\ \\//\ \      __    ____
/\ '__`\  /'__`\   /'_` \  /'_` \ \ \ \   /'__`\ /',__\
\ \ \L\ \/\ \L\.\_/\ \L\ \/\ \L\ \ \_\ \_/\  __//\__, `\
 \ \ ,__/\ \__/.\_\ \___,_\ \___,_\/\____\ \____\/\____/
  \ \ \/  \/__/\/_/\/__,_ /\/__,_ /\/____/\/____/\/___/
   \ \_\  has now set you up for Laravel development!
    \/_/
	EOF
    printf "$RESET"

    instructions
}

main "$@"
