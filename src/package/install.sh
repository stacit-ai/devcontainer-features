#!/bin/bash
set -euo pipefail

PACKAGE_OPT="${PACKAGE:-}"
APT_OPT="${APT:-}"
DNF_OPT="${DNF:-}"
APK_OPT="${APK:-}"
PACMAN_OPT="${PACMAN:-}"
ZYPPER_OPT="${ZYPPER:-}"

trim_whitespace() {
    value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

normalize_package_list() {
    printf '%s\n' "$1" | tr ',' '\n' | while IFS= read -r package_name; do
        package_name="$(trim_whitespace "$package_name")"
        if [ -n "$package_name" ]; then
            printf '%s\n' "$package_name"
        fi
    done
}

detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        printf '%s\n' "apt"
    elif command -v dnf >/dev/null 2>&1; then
        printf '%s\n' "dnf"
    elif command -v yum >/dev/null 2>&1; then
        printf '%s\n' "yum"
    elif command -v apk >/dev/null 2>&1; then
        printf '%s\n' "apk"
    elif command -v pacman >/dev/null 2>&1; then
        printf '%s\n' "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        printf '%s\n' "zypper"
    else
        echo "ERROR: unsupported package manager for package feature" >&2
        exit 1
    fi
}

get_manager_packages() {
    case "$1" in
        apt) printf '%s\n' "$APT_OPT" ;;
        dnf | yum) printf '%s\n' "$DNF_OPT" ;;
        apk) printf '%s\n' "$APK_OPT" ;;
        pacman) printf '%s\n' "$PACMAN_OPT" ;;
        zypper) printf '%s\n' "$ZYPPER_OPT" ;;
        *)
            echo "ERROR: unsupported package manager for package feature: $1" >&2
            exit 1
            ;;
    esac
}

collect_packages() {
    manager_packages="$(get_manager_packages "$1")"
    {
        normalize_package_list "$PACKAGE_OPT"
        normalize_package_list "$manager_packages"
    }
}

install_apt_packages() {
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

install_dnf_packages() {
    dnf install -y "$@"
}

install_yum_packages() {
    yum install -y "$@"
}

install_apk_packages() {
    apk add --no-cache "$@"
}

install_pacman_packages() {
    pacman -Sy --noconfirm "$@"
}

install_zypper_packages() {
    zypper --non-interactive install --no-recommends "$@"
}

install_packages() {
    package_manager="$1"
    shift

    case "$package_manager" in
        apt) install_apt_packages "$@" ;;
        dnf) install_dnf_packages "$@" ;;
        yum) install_yum_packages "$@" ;;
        apk) install_apk_packages "$@" ;;
        pacman) install_pacman_packages "$@" ;;
        zypper) install_zypper_packages "$@" ;;
        *)
            echo "ERROR: unsupported package manager for package feature: $package_manager" >&2
            exit 1
            ;;
    esac
}

main() {
    package_manager="$(detect_package_manager)"
    packages="$(collect_packages "$package_manager")"

    if [ -z "$packages" ]; then
        echo "WARNING: no packages were requested; nothing was installed." >&2
        return 0
    fi

    # Package names are expected not to contain whitespace.
    # shellcheck disable=SC2086
    set -- $packages

    echo "Installing packages with $package_manager: $*"
    install_packages "$package_manager" "$@"
}

main "$@"
