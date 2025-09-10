#!/usr/bin/env bash
# Minimal loading animations and colored output helpers

BLA_GREEN=$(tput setaf 2)
BLA_RED=$(tput setaf 1)
BLA_YELLOW=$(tput setaf 3)
BLA_BLUE=$(tput setaf 4)
BLA_BOLD=$(tput bold)
BLA_RESET=$(tput sgr0)

BLA_SPINNER_PID=0

BLA::green() {
  printf "%s%s%s" "$BLA_GREEN" "$1" "$BLA_RESET"
}

BLA::red() {
  printf "%s%s%s" "$BLA_RED" "$1" "$BLA_RESET"
}

BLA::yellow() {
  printf "%s%s%s" "$BLA_YELLOW" "$1" "$BLA_RESET"
}

BLA::blue() {
  printf "%s%s%s" "$BLA_BLUE" "$1" "$BLA_RESET"
}

BLA::bold() {
  printf "%s%s%s" "$BLA_BOLD" "$1" "$BLA_RESET"
}

BLA::print_success() {
  BLA::green "✅ $1\n"
}

BLA::print_error() {
  BLA::red "❌ $1\n"
}

BLA::print_warning() {
  BLA::yellow "$1\n"
}

BLA::print_info() {
  BLA::blue "$1\n"
}

BLA::start_loading_animation() {
  local message="$1"
  local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local i=0
  tput civis
  printf "%s " "$message"
  while true; do
    printf "\r%s %s" "$message" "${frames[i]}"
    i=$(( (i + 1) % ${#frames[@]} ))
    sleep 0.1
  done &
  BLA_SPINNER_PID=$!
}

BLA::stop_loading_animation() {
  if [ "$BLA_SPINNER_PID" -ne 0 ]; then
    kill "$BLA_SPINNER_PID" >/dev/null 2>&1 || true
    wait "$BLA_SPINNER_PID" 2>/dev/null || true
    BLA_SPINNER_PID=0
  fi
  tput cnorm
  printf "\r"
}
