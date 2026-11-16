#!/bin/bash
# macOS read-only diagnostics; --verify-key explicitly opts into SSH + whoami.
set -u
usage() {
    printf 'Usage: bash %s TARGET [--verify-key] [--identity PRIVATE_KEY]\n' "$0"
}
if [[ $# -eq 0 ]]; then usage >&2; exit 2; fi
if [[ "$1" == --help || "$1" == -h ]]; then usage; exit 0; fi
target=$1
shift
if [[ "$target" == -* ]]; then usage >&2; exit 2; fi
verify=0
identity=''
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verify-key) verify=1; shift ;;
        --identity)
            if [[ $# -lt 2 ]]; then usage >&2; exit 2; fi
            identity=$2; shift 2 ;;
        *) usage >&2; exit 2 ;;
    esac
done
if [[ -n "$identity" && "$verify" -eq 0 ]]; then
    printf '%s\n' '--identity requires --verify-key' >&2
    exit 2
fi
if [[ "$(uname -s)" != Darwin ]]; then
    printf '%s\n' 'This checker requires macOS (nc -G and dscacheutil).' >&2
    exit 2
fi
if ! config=$(ssh -G "$target"); then exit 2; fi
host=$(printf '%s\n' "$config" | awk '$1 == "hostname" {print $2; exit}')
user=$(printf '%s\n' "$config" | awk '$1 == "user" {print $2; exit}')
port=$(printf '%s\n' "$config" | awk '$1 == "port" {print $2; exit}')
printf 'Target: %s -> %s@%s:%s\n' "$target" "$user" "$host" "$port"
printf '%s\n' "$config" | awk '$1 ~ /^(identityfile|proxyjump|proxycommand)$/ {print}'
if printf '%s\n' "$config" | awk '$1 ~ /^(proxyjump|proxycommand)$/ && $2 != "none" {found=1} END {exit !found}'; then
    printf '%s\n' 'Proxy configured: this direct Tailscale checker does not model the proxy path.' >&2
    exit 2
fi
printf '\nSystem name resolution:\n'
dscacheutil -q host -a name "$host"
ts_bin=''
if command -v tailscale >/dev/null 2>&1; then
    ts_bin=$(command -v tailscale)
elif [[ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]]; then
    ts_bin=/Applications/Tailscale.app/Contents/MacOS/Tailscale
fi
if [[ -n "$ts_bin" ]]; then
    printf '\nTailscale status:\n'
    "$ts_bin" status
    printf '\nTailscale probe (independent of TCP result):\n'
    "$ts_bin" ping --c 1 --timeout 3s "$host"
else
    printf '\nTailscale CLI not found; tunnel status not checked.\n'
fi
printf '\nTCP check:\n'
if nc -vz -G 5 "$host" "$port"; then
    tcp_result=0
else
    tcp_result=1
fi
if [[ "$verify" -eq 0 ]]; then
    printf '\nAuthentication not tested. Exit code reflects TCP reachability only.\n'
    exit "$tcp_result"
fi
if [[ "$tcp_result" -ne 0 ]]; then exit 1; fi
args=(-o BatchMode=yes -o ConnectTimeout=8 -o ConnectionAttempts=1
      -o ServerAliveInterval=5 -o ServerAliveCountMax=1
      -o PreferredAuthentications=publickey -o PasswordAuthentication=no
      -o KbdInteractiveAuthentication=no -o StrictHostKeyChecking=yes
      -o UpdateHostKeys=no -o ClearAllForwardings=yes -o PermitLocalCommand=no
      -o ControlMaster=no -o ControlPath=none -T)
if [[ -n "$identity" ]]; then args+=(-o IdentitiesOnly=yes -i "$identity"); fi
printf '\nPublic-key-only login (expected remote user: %s):\n' "$user"
if remote_user=$(ssh "${args[@]}" "$target" whoami); then
    printf 'Remote user: %s\n' "$remote_user"
    if [[ "$remote_user" == "$user" ]]; then
        printf '%s\n' 'Public-key login verified.'
        exit 0
    fi
    printf '%s\n' 'Remote user differs from the effective SSH user; investigate before reporting success.' >&2
fi
exit 1
