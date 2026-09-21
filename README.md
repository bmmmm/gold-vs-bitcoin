# gold-vs-bitcoin

**What runs out first — Earth's gold reserves, or the last bitcoin ever mined?**

One static page, one verdict, live counters:
**<https://bmmmm.github.io/gold-vs-bitcoin/>**

## The short answer

🥇 **Gold — by about a century.** Known economic reserves (~66,000 t per USGS)
are exhausted around **~2046** at current mining rates (~3,300 t/year), while
Bitcoin's issuance halves every ~4 years and the **last satoshi** isn't mined
until **~2139** (the page computes this live, off the block pace in
`btc-blockms-log.csv` — this number and the `og:description` above are a
manual snapshot and can lag a year behind if `btc-anchor-sync` nudges the
projection across a year boundary).

The asterisks make it fun:

- Gold "reserves" are a moving target — between the 2025 and 2026 USGS editions
  they went *up* from 64,000 to 66,000 t even as ~3,300 t were mined, because
  new deposits keep being found and reclassified. Bitcoin's finish line is
  fixed in the protocol.
- Bitcoin is already ~95% mined, yet the remaining ~5% takes another century —
  issuance approaches zero asymptotically (see the charts on the page).
- Plot twist: gold never dies (virtually all ~219,500 t ever mined still exist,
  ~1,400 t/yr comes back via recycling), while bitcoin only dies — an estimated
  3–4M BTC are lost forever, so the effective cap is likely below 18M.
- Bonus: everything ever mined fits in a ~22.5 m cube.

## How it works

A single `index.html` — no build step, no dependencies, no network calls in
the browser. The counters and charts are client-side estimates derived from
published anchors (USGS reserves + production, the 2024 halving block), not
live market data.

The Bitcoin side is mostly protocol math, but `BTC.blockMs` (the assumed
average ms per block, everything else — left-to-mine, next halving, next
block, last satoshi — is extrapolated from it) drifts slowly from the
10-minute target as network hashrate moves. A weekly GitHub Action
(`.github/workflows/btc-anchor-sync.yml`, script:
`scripts/sync-btc-blockms.sh`) fetches the current chain tip, recomputes the
empirical average since the block-840000 anchor, and — fully autonomously,
no approval step — pushes the correction straight to `index.html` when it
has moved by at least 300ms (below that it's weekly noise, not signal; two
sanity bands, absolute and delta-relative, refuse anything that looks like a
bad API response rather than real drift), then triggers a Pages redeploy
directly (a `GITHUB_TOKEN` push doesn't fire `pages.yml` on its own). Every
run, changed or not, is logged to `btc-blockms-log.csv`, and the page itself
shows the current drift and last-checked date in the fine print at the
bottom — flagged if a sync is overdue. The halving anchor itself (block
840000) is never touched by the script; that's a manual re-anchor once the
5th halving lands (~2028).

Note: this Action only ever pushes to the `github` remote — the Forgejo
`origin` mirror will drift behind on weeks it corrects `index.html`, same as
any other GitHub-only commit, until someone re-syncs it by hand. Because
`btc-blockms-log.csv` is append-only on both sides once that happens, the
next `git pull` from `origin` will conflict on that file every time — not a
sign anything is wrong, just take GitHub's version (`git checkout --theirs`)
or merge the rows by hand.

The gold anchors get refreshed once a year by hand, when the USGS publishes
new figures (each February) — there's no live feed for reserves to sync
against.

## Sources

- [USGS Mineral Commodity Summaries 2026 — Gold](https://pubs.usgs.gov/periodicals/mcs2026/mcs2026-gold.pdf)
- [World Gold Council — above-ground stocks](https://www.gold.org/goldhub/data/how-much-gold)
- [Bitcoin Wiki — controlled supply](https://en.bitcoin.it/wiki/Controlled_supply)
- [River — how many bitcoins are lost](https://river.com/learn/how-many-bitcoins-are-lost/)

Not financial advice. Estimates, not prophecy.

## License

[CC-BY-4.0](LICENSE) — this is a content/infographic page; the trivial inline
script is covered by the same license.

## Support

If this settled a bar bet: [Ko-fi](https://ko-fi.com/bmabma).
