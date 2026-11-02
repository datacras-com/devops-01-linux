#!/usr/bin/env bash
# İstifadə: ./test.sh [NN ...]   — dərsləri təmiz Ubuntu 24.04 konteynerində --auto ilə sınayır
cd "$(dirname "$0")" || exit 1
nums=("$@"); [ ${#nums[@]} -gt 0 ] || nums=($(ls lessons | cut -d- -f1))
fail=0
for n in "${nums[@]}"; do
  out=$(docker run --rm -v "$PWD:/lab:ro" -e LAB_HOME=/tmp/dl -e LAB_DELAY=0 -e DEBIAN_FRONTEND=noninteractive ubuntu:24.04 bash -c "cd /lab && ./run $n --auto" 2>&1); rc=$?
  clean=$(printf '%s' "$out" | sed 's/\x1b\[[0-9;]*m//g')
  bad=$(printf '%s' "$clean" | grep -c '❌')
  if [ $rc -eq 0 ] && [ "$bad" -eq 0 ]; then echo "✅ $n"; else echo "❌ $n (exit=$rc, ❌=$bad)"; printf '%s\n' "$clean" | grep -E '❌|⚠' | head -8; fail=1; fi
done
exit $fail
