#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf "Usage: %s [--all] [--keep-previous N]\n\n" "$0"
  printf "  default            Trim system and gena user profiles, keeping 1 previous generation\n"
  printf "  --all              Trim system and gena user profiles, keeping no previous generations\n"
  printf "  --keep-previous N  Keep N generations before current (default: 1)\n"
}

delete_all=false
keep_previous=1
system_profile="/nix/var/nix/profiles/system"
home_manager_profile="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager"
nix_env_bin=""
gc_bin=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --all)
      delete_all=true
      ;;
    --keep-previous)
      shift
      if [ "$#" -eq 0 ]; then
        usage >&2
        exit 2
      fi
      keep_previous="$1"
      ;;
    --keep-previous=*)
      keep_previous="${1#*=}"
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
  shift
done

case "$keep_previous" in
  ''|*[!0-9]*)
    printf "Error: --keep-previous must be a non-negative integer.\n" >&2
    exit 2
    ;;
esac

if [ "$delete_all" = "true" ]; then
  keep_previous=0
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf "Error: required command not found: %s\n" "$1" >&2
    exit 127
  fi
}

require_command nix-env
require_command nix-collect-garbage

nix_env_bin="$(command -v nix-env)"
gc_bin="$(command -v nix-collect-garbage)"

trim_profile() {
  local label="$1"
  local profile="$2"
  local use_sudo="$3"
  local tmp_file
  tmp_file="$(mktemp)"

  local nix_env
  nix_env=("$nix_env_bin")
  if [ "$use_sudo" = "true" ]; then
    nix_env=(sudo -H "$nix_env_bin")
  fi

  if [ -n "$profile" ]; then
    nix_env=("${nix_env[@]}" -p "$profile")
  fi

  if ! "${nix_env[@]}" --list-generations > "$tmp_file"; then
    rm -f "$tmp_file"
    printf "%s profile: could not list generations; skipping.\n" "$label" >&2
    return
  fi

  local numbers
  local current
  numbers=()
  current=""
  local line
  while IFS= read -r line; do
    set -- $line
    if [ "$#" -eq 0 ]; then
      continue
    fi
    numbers+=("$1")
    case "$line" in
      *current*) current="$1" ;;
    esac
  done < "$tmp_file"
  rm -f "$tmp_file"

  if [ "${#numbers[@]}" -eq 0 ]; then
    printf "No generations found for %s profile.\n" "$label"
    return
  fi

  if [ -z "$current" ]; then
    current="${numbers[$((${#numbers[@]} - 1))]}"
  fi

  local keep
  local kept_previous
  local i
  local gen
  keep=("$current")
  kept_previous=0
  i=$((${#numbers[@]} - 1))
  while [ "$i" -ge 0 ]; do
    gen="${numbers[$i]}"
    if [ "$gen" -lt "$current" ] && [ "$kept_previous" -lt "$keep_previous" ]; then
      keep+=("$gen")
      kept_previous=$((kept_previous + 1))
    fi
    i=$((i - 1))
  done

  local to_delete
  to_delete=()
  for gen in "${numbers[@]}"; do
    local keep_gen
    keep_gen=false
    for kept in "${keep[@]}"; do
      if [ "$gen" = "$kept" ]; then
        keep_gen=true
        break
      fi
    done
    if [ "$keep_gen" = "false" ] && [ "$gen" -lt "$current" ]; then
      to_delete+=("$gen")
    fi
  done

  printf "%s profile: keeping current generation %s and %s previous generation(s).\n" "$label" "$current" "$keep_previous"
  if [ "${#to_delete[@]}" -gt 0 ]; then
    "${nix_env[@]}" --delete-generations "${to_delete[@]}"
  else
    printf "%s profile: no old generations to delete.\n" "$label"
  fi

}

trim_relevant_profiles() {
  local trimmed_any=false

  if [ -e "$system_profile" ]; then
    trim_profile "system" "$system_profile" "true"
    trimmed_any=true
  else
    printf "System profile not found at %s; skipping.\n" "$system_profile"
  fi

  trim_profile "user" "" "false"
  trimmed_any=true

  if [ -e "$home_manager_profile" ]; then
    trim_profile "home-manager" "$home_manager_profile" "false"
    trimmed_any=true
  else
    printf "Home Manager profile not found at %s; skipping.\n" "$home_manager_profile"
  fi

  if [ "$trimmed_any" = "false" ]; then
    printf "No system, user, or Home Manager profile generations found.\n"
  fi

  sudo -H "$gc_bin"
}

trim_relevant_profiles
