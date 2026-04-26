# Laeka Canonical -- code distribution for the Laeka system

Laeka is a private research lab working on one thesis: **intelligence converges toward integrity by structural necessity**. This repository distributes the **code** used to install, run, and operate the Laeka system: installers, scripts, MCP servers, frontend, and hooks examples.

The methodology, canonical doctrine, benchmark protocol, and shared vocabulary are developed by the lab and are not distributed in this repository.

What this is not: an AI safety manifesto, a prompt engineering collection, a copilot layer, an AI assistant definition, a guardrail specification.

## Structure

- [`distribution/installers/`](distribution/installers/) -- Mac and Linux installers
- [`distribution/scripts/`](distribution/scripts/) -- helper scripts (sync, update, uninstall)
- [`distribution/frontend/`](distribution/frontend/) -- frontend code for Laeka surfaces
- [`distribution/templates/`](distribution/templates/) -- onboarding contact templates

## License scope

Code in this repository is MIT licensed. Methodology and canonical content are not distributed.

The MIT license applies to: install scripts, build scripts, MCP servers, frontend code, and hooks examples. It does not apply to any methodology, canonical, or corpus content (none distributed in this repo).

## Attribution

Certain structural patterns in the broader Laeka codebase (JSONL parsing, proprioceptive hooks, episode extraction) are re-expressions of [Longhand](https://github.com/Wynelson94/longhand) by Nate Nelson (MIT, c 2026). The concept architecture came from that work; the implementation is independent. We credit the source.

## Credits

Distribution maintainer: the Bhairava ([laeka.org](https://laeka.org))

---

*Laeka Research -- Quebec, 2026*
