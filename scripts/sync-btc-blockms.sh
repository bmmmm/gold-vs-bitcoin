#!/usr/bin/env bash
# Recalibrates BTC.blockMs in index.html — the assumed average milliseconds
# per block that every on-page projection (left-to-mine, next halving, next
# block, last satoshi) is extrapolated from.
#
# BTC.anchorHeight/anchorTime stay fixed at the 4th halving block (840000);
# that is a meaningful, citable point in protocol history and this script
# never touches it. blockMs is the one assumption that drifts, because the
# network's real average pace (driven by hashrate, only nudged back toward
# 10 min every 2016-block difficulty retarget) is never exactly 600000ms.
# This computes the empirical average since the anchor from the live chain
# tip and, if it has moved enough to matter, corrects blockMs to match.
#
# Gold has no equivalent: USGS reserves are a once-a-year PDF, not a live
# feed, so GOLD.* stays a manual annual edit (see README).
#
# Fully autonomous (no PR, no approval step) — which means this script is
# the only gate before a number changes on a public page. Exits non-zero
# (loud, not silent) on any API or sanity-check failure; a bad correction
# is worse than a missed one, and a missed one is caught next Monday. Every
# sed rewrite below is followed by a re-grep that confirms it actually took
# — a no-op match is not allowed to look like success.
#
# Run from repo root.
set -euo pipefail

FILE="index.html"
LOG="btc-blockms-log.csv"
API="https://mempool.space/api"

EXPECT_ANCHOR_HEIGHT=840000

# Below this, a change is noise, not signal: at ~128k blocks since the
# anchor a single new block moves the running average by only a few ms
# (observed: ~6ms/week), which would otherwise turn every weekly run into a
# "fix: recalibrate" commit nobody can perceive on the page (delta_pct is
# shown to 2 decimals, i.e. the display itself can't resolve below ~0.005%
# of current_ms). syncedAt/the log still update every run regardless — this
# threshold only gates the blockMs *value* write.
MIN_DELTA_MS=300

: "${GITHUB_OUTPUT:=/dev/null}"

# Patterns require the trailing comma from the real source formatting
# (`key: 123,`), not just a digit run — otherwise a reformat like
# `597_083` (valid JS, invalid to us) would grep-match the "597" prefix and
# silently misinterpret it as a wrong-but-plausible number instead of
# tripping the "couldn't find" guard below.
anchor_height=$(grep -oE 'anchorHeight: [0-9]+,' "$FILE" | grep -oE '[0-9]+' || true)
if [[ -z "$anchor_height" ]]; then
    echo "sync-btc-blockms: couldn't find 'anchorHeight: <digits>,' in $FILE" \
         "at all — formatting changed, fix the grep pattern below." >&2
    exit 1
fi
if [[ "$anchor_height" != "$EXPECT_ANCHOR_HEIGHT" ]]; then
    echo "sync-btc-blockms: index.html anchorHeight is $anchor_height, this" \
         "script still expects $EXPECT_ANCHOR_HEIGHT (the 4th halving)." >&2
    echo "Someone re-anchored to a newer halving — update EXPECT_ANCHOR_HEIGHT" \
         "and the anchor_ts lookup below to match, then re-run." >&2
    exit 1
fi

# anchorTime in index.html is a JS Date.UTC(2024, 3, 20, 0, 9, 27) call, not
# a plain number — parsing that in bash is more fragile than just asserting
# the one known-good pair. Verified against mempool.space at anchor time:
# block 840000 landed at unix 1713571767 (2024-04-20 00:09:27 UTC), which is
# exactly what index.html's Date.UTC(...) now evaluates to.
anchor_ts=1713571767

current_ms=$(grep -oE 'blockMs: [0-9]+,' "$FILE" | grep -oE '[0-9]+' || true)
if [[ -z "$current_ms" ]]; then
    echo "sync-btc-blockms: couldn't find 'blockMs: <digits>,' in $FILE" \
         "— formatting changed, fix the grep pattern below." >&2
    exit 1
fi

tip_height=$(curl -sf --max-time 30 --retry 3 --retry-all-errors "$API/blocks/tip/height")
[[ "$tip_height" =~ ^[0-9]+$ ]] || { echo "sync-btc-blockms: bad tip height '$tip_height'" >&2; exit 1; }

tip_hash=$(curl -sf --max-time 30 --retry 3 --retry-all-errors "$API/block-height/$tip_height")
[[ "$tip_hash" =~ ^[0-9a-f]{64}$ ]] || { echo "sync-btc-blockms: bad tip hash '$tip_hash'" >&2; exit 1; }

tip_ts=$(curl -sf --max-time 30 --retry 3 --retry-all-errors "$API/block/$tip_hash" | grep -oE '"timestamp":[0-9]+' | grep -oE '[0-9]+' || true)
[[ "$tip_ts" =~ ^[0-9]+$ ]] || { echo "sync-btc-blockms: bad tip timestamp '$tip_ts'" >&2; exit 1; }

blocks=$(( tip_height - anchor_height ))
seconds=$(( tip_ts - anchor_ts ))
if (( blocks <= 0 || seconds <= 0 )); then
    echo "sync-btc-blockms: non-positive span (blocks=$blocks seconds=$seconds)" >&2
    exit 1
fi

new_ms=$(( (seconds * 1000 + blocks / 2) / blocks ))

# Two sanity checks, not one. The absolute band alone (+/-8.3% of the
# 10-min target) is ~470x wider than any real weekly move of a ~2.4-year
# running average — a bad API response (wrong height, forked/stale tip)
# could land inside 550000..650000 and still be garbage. The delta band
# catches that: a single week can't legitimately move a multi-year average
# by more than 5%.
if (( new_ms < 550000 || new_ms > 650000 )); then
    echo "sync-btc-blockms: computed blockMs=$new_ms is outside the sane" \
         "550000..650000 band — refusing to apply, check the API response." >&2
    exit 1
fi
delta_ms=$(( new_ms - current_ms ))
delta_abs=${delta_ms#-}
max_delta=$(( current_ms / 20 ))  # 5%
if (( delta_abs > max_delta )); then
    echo "sync-btc-blockms: computed blockMs=$new_ms is ${delta_ms}ms from" \
         "current=$current_ms — more than 5% in one run, refusing to apply." >&2
    exit 1
fi

# Bash integer math truncates; good enough for a log column, not the write.
delta_pct=$(awk -v d="$delta_ms" -v c="$current_ms" 'BEGIN { printf "%.4f", 100*d/c }')

echo "sync-btc-blockms: tip=$tip_height empirical_blockMs=$new_ms current=$current_ms delta=${delta_pct}%"

# syncedAt stamps "last checked", not "last changed" — update it every run,
# including no-drift ones, so the on-page note never claims a check that
# didn't happen. Done before the log write: if this fails, nothing else
# below has written anything yet, so the run leaves no half-applied state.
# 10# forces base-10 (date -u pads with zeros, bash would otherwise read
# "08"/"09" as invalid octal).
sync_year=$(date -u +%Y)
sync_month0=$(( 10#$(date -u +%m) - 1 ))
sync_day=$(( 10#$(date -u +%d) ))
before=$(grep -oE 'syncedAt: Date\.UTC\([0-9]+, [0-9]+, [0-9]+\)' "$FILE" || true)
[[ -n "$before" ]] || { echo "sync-btc-blockms: couldn't find 'syncedAt: Date.UTC(...)' in $FILE" >&2; exit 1; }
sed -i.bak -E "s/(syncedAt: Date\.UTC\()[0-9]+, [0-9]+, [0-9]+(\))/\\1${sync_year}, ${sync_month0}, ${sync_day}\\2/" "$FILE" && rm -f "$FILE.bak"
after=$(grep -oE 'syncedAt: Date\.UTC\([0-9]+, [0-9]+, [0-9]+\)' "$FILE")
if [[ "$after" != "syncedAt: Date.UTC(${sync_year}, ${sync_month0}, ${sync_day})" ]]; then
    echo "sync-btc-blockms: syncedAt rewrite didn't take (before='$before' after='$after')" >&2
    exit 1
fi

date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
if [[ ! -f "$LOG" ]]; then
    echo "date_utc,tip_height,tip_timestamp_utc,anchor_height,blocks_since_anchor,current_block_ms,measured_block_ms,delta_pct" > "$LOG"
fi
echo "$date_utc,$tip_height,$tip_ts,$anchor_height,$blocks,$current_ms,$new_ms,$delta_pct" >> "$LOG"

{
    echo "delta_pct=$delta_pct"
    echo "tip_height=$tip_height"
} >> "$GITHUB_OUTPUT"

if (( delta_abs >= MIN_DELTA_MS )); then
    sed -i.bak -E "s/(blockMs: )[0-9]+,/\\1${new_ms},/" "$FILE" && rm -f "$FILE.bak"
    written=$(grep -oE 'blockMs: [0-9]+,' "$FILE" | grep -oE '[0-9]+' || true)
    if [[ "$written" != "$new_ms" ]]; then
        echo "sync-btc-blockms: blockMs rewrite didn't take (wanted $new_ms, file has '$written')" >&2
        exit 1
    fi
    {
        echo "changed=true"
        echo "old_ms=$current_ms"
        echo "new_ms=$new_ms"
    } >> "$GITHUB_OUTPUT"
else
    echo "changed=false" >> "$GITHUB_OUTPUT"
fi
