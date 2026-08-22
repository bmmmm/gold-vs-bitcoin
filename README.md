# gold-vs-bitcoin

**What runs out first — Earth's gold reserves, or the last bitcoin ever mined?**

One static page, one verdict, live counters:
**<https://bmmmm.github.io/gold-vs-bitcoin/>**

## The short answer

🥇 **Gold — by about a century.** Known economic reserves (~66,000 t per USGS)
are exhausted around **~2046** at current mining rates (~3,300 t/year), while
Bitcoin's issuance halves every ~4 years and the **last satoshi** isn't mined
until **~2140**.

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

A single `index.html` — no build step, no dependencies, no network calls.
The counters and charts are client-side estimates derived from published
anchors (USGS reserves + production, the 2024 halving block), not live market
data. The Bitcoin side maintains itself (it's all protocol math); the gold
anchors get refreshed once a year when the USGS publishes new figures
(each February).

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
