[![Türkçe sürüm](https://img.shields.io/badge/Language-T%C3%BCrk%C3%A7e-E30A17?style=for-the-badge)](README.tr.md)

# Case Study — Smart-Contract Security Audit (Immunefi Bug Bounty, Arbitrum One)

**Role:** Independent security researcher (solo)
**Target:** Variational — public Immunefi bug bounty program, Arbitrum One (chainId 42161)
**Duration:** 2 focused work sessions
**Outcome:** **NO-GO — no qualifying vulnerability. Nothing submitted.**

> **In plain terms (for non-technical readers).** An investment platform was holding about $16.7
> million of user funds in self-executing code, with a public standing offer: find a way to break it
> and get paid. I investigated the most promising weakness end-to-end and built a working simulation
> against the platform's real, live configuration. The simulation showed that the observed condition
> was recoverable within the same transaction and did not create a qualifying vulnerability. I
> documented the refutation and stopped the review without submitting a report.

---

## Why a "nothing found" case study

This engagement shows a **disciplined negative result**. On a heavily audited target, a false positive
can consume review time and produce a weak submission. The relevant deliverable is therefore the
decision boundary as well as the investigation.

The deliverable here is a decision backed by executable evidence: **stop, and here is precisely why.**

---

## What the engagement required

1. Establish exactly what the program pays for, and freeze those rules with a timestamp.
2. Pin the on-chain state to a single block so every later claim is reproducible.
3. Obtain the **exact deployed** source — not a similarly-named public repo.
4. Model the system's money flows, trust boundaries, and security invariants before hunting.
5. Test the strongest hypothesis with a runnable proof, and accept the result either way.

---

## Selected technical work

**On-chain forensics (read-only JSON-RPC).**
Discovered that two of the three assets named in the bounty scope were **externally-owned accounts
with no contract code** — wallets holding ~11.7M and ~5.0M USDC respectively. This collapsed the real
attack surface to a single deployed contract plus the minimal-proxy clones it deploys. Enumerating
contract-creation events across ~45M blocks showed **38,485 deployed clones**, each verified
byte-for-byte as an EIP-1167 minimal proxy pointing at one implementation.

**Source provenance and bytecode reproduction.**
Retrieved verified sources for all three code-bearing contracts, recorded compiler settings
(solc 0.8.28, optimizer runs=20000), and confirmed the deployed runtime bytecode matched the published
source. Recorded the keccak256 of each deployed runtime and re-verified them at the pinned block
inside the fork before trusting any test result.

**Invariant specification.**
Wrote 14 invariants across custody, replay/uniqueness, pool identity, liveness, token behaviour and
upgradeability — each with a formal predicate, the enforcing code at `file:line`, its assumptions, and
the single most plausible way it breaks. Hypotheses were derived from the spec, not from intuition.

**Fork-based proof of concept.**
Built a Foundry harness forking Arbitrum at a pinned block against the **real deployed contracts**,
and tested the leading hypothesis end-to-end, including a **negative control** and a cost boundary
test. All three tests pass — and they prove the hypothesis is **not** a payable issue: the condition is
recoverable by the protocol operator within the same transaction, so no non-privileged user's funds are
durably affected. See `evidence/`.

**Prior-art and duplicate analysis.**
Located and archived the target's public third-party security review (SHA-256 recorded), mapped its two
disclosed High findings against the currently deployed code — establishing that one was already
remediated by redesign and the other was a privileged/acknowledged issue — and documented that a
substantial set of the review's findings were **not publicly disclosed**, making duplicate risk
unquantifiable. The decision records that risk as unknown.

---

## The decision

The system proved to be a thin, operator-custodial settlement layer: user collateral could only be
moved by a privileged operator role, and there was exactly **one** unprivileged state-mutating entry
point. The most promising hypothesis was reproduced on a fork, then **refuted by its own evidence** —
the observed effect was recoverable immediately and cost the attacker more than the victim.

Three independent refutation passes, each mandated to *disprove* rather than support the hypothesis,
reached the same conclusion with consistent code citations.

**Result: NO-GO.** No report was submitted. Recommendation delivered: redirect effort to a target
with a structurally better payoff profile.

---

## Professional posture

- **Read-only against mainnet.** No transaction was ever broadcast. All exploit testing ran on a local
  fork. No live infrastructure was probed or stressed.
- **No disclosure.** The target program requires approval prior to publication. Because the engagement
  produced no reportable finding, there is nothing owed to the program — and the specific mechanism
  examined is deliberately **not** detailed in this public case study.
- **Unknowns remain explicit.** An unavailable report and a pruned archive-node result are recorded
  as UNKNOWN rather than estimated.

---

## Artifacts

| File | Contents |
|---|---|
| `../../METHODOLOGY.md` | The engineering standard followed throughout |
| `evidence/reproducibility.md` | Toolchain freeze, pinned block, code-hash verification, test output |
| `evidence/ForkPoC.t.sol` | The Foundry fork test (mechanism-neutral excerpt) |
| `private-annex/` | Full findings, invariant spec and unredacted PoC — available on request |

## Stack used

Solidity · Foundry (forge / cast / anvil) · EVM fork testing · JSON-RPC on-chain forensics ·
EIP-1167 minimal proxies · EIP-1967 proxy slots · ERC-20 accounting · Node.js tooling · Git
