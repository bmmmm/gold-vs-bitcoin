# gold-vs-bitcoin

**What runs out first — Earth's gold reserves, or the last bitcoin ever mined?**

One static page, one verdict, live counters:
**<https://bmmmm.github.io/gold-vs-bitcoin/>**

## The short answer

🥇 **Gold — by about a century.** Known economic reserves (~64,000 t per USGS)
are exhausted around **~2044** at current mining rates (~3,300 t/year), while
Bitcoin's issuance halves every ~4 years and the **last satoshi** isn't mined
until **~2140**.

Two asterisks make it fun:

- Gold "reserves" are a moving target — the number has hovered near two
  decades' worth *for decades*, because new deposits keep getting found and
  reclassified. Bitcoin's finish line is fixed in the protocol.
- Bitcoin is already ~95% mined, yet the remaining ~5% takes another century —
  issuance approaches zero asymptotically.

## How it works

A single `index.html` — no build step, no dependencies, no network calls.
The counters are client-side estimates derived from published anchors
(USGS reserves + production, the 2024 halving block), not live market data.

## Sources

- [USGS Mineral Commodity Summaries 2025 — Gold](https://pubs.usgs.gov/periodicals/mcs2025/mcs2025-gold.pdf)
- [World Gold Council — above-ground stocks](https://www.gold.org/goldhub/data/how-much-gold)
- [Bitcoin Wiki — controlled supply](https://en.bitcoin.it/wiki/Controlled_supply)

Not financial advice. Estimates, not prophecy.

## License

[CC-BY-4.0](LICENSE) — this is a content/infographic page; the trivial inline
script is covered by the same license.

## Support

If this settled a bar bet: [Ko-fi](https://ko-fi.com/bmabma).
