[![Türkçe sürüm](https://img.shields.io/badge/Language-T%C3%BCrk%C3%A7e-E30A17?style=for-the-badge)](README.tr.md)

# Case study: smart-contract security audit (Immunefi bug bounty, Arbitrum One)

- Role: independent security researcher
- Target: Variational, a public Immunefi bug bounty program on Arbitrum One (chainId 42161)
- Duration: 2 focused work sessions
- Outcome: **NO-GO.** No qualifying vulnerability; nothing submitted.

> For non-technical readers: a platform whose settlement logic runs in smart contracts, with about
> $16.7 million of user funds in two operator wallets, had a public standing offer to pay anyone who
> found a way to break it. I took the most promising weakness and followed it end to end, with a
> working simulation against the platform's real, live configuration. It did not hold up. The
> condition I had observed could be undone within the same transaction, and it was not a qualifying
> vulnerability. I wrote down why and stopped the review without submitting a report.

## Why a "nothing found" case study

The engagement ended with nothing found. This page is about how I got there. On a target that has
been audited heavily, a false positive can eat review time and end up as a weak submission.
Knowing where to stop is part of the job. Here the outcome was a decision to stop, and the evidence
behind it is executable.

## What the engagement required

1. Establish exactly what the program pays for, and freeze those rules with a timestamp.
2. Pin the on-chain state to a single block so every later claim is reproducible.
3. Obtain the source of the exact deployed contracts. A public repo with a similar name does not count.
4. Model the system's money flows, trust boundaries and security invariants before hunting.
5. Test the strongest hypothesis with a runnable proof, and accept the result either way.

## Selected technical work

### On-chain forensics (read-only JSON-RPC)

The bounty scope named three assets. Two of them turned out to be externally-owned accounts with no
contract code: wallets holding ~11.7M and ~5.0M USDC. So the real attack surface was a single
deployed contract, plus the minimal-proxy clones it deploys. I enumerated contract-creation events
across ~45M blocks and found 38,485 deployed clones. Each one checked out byte-for-byte as an
EIP-1167 minimal proxy pointing at one implementation.

### Source provenance

I retrieved the verified sources for all three contracts that carry code, recorded the compiler
settings (solc 0.8.28, optimizer runs=20000) and confirmed that the deployed runtime bytecode matched
the published source: two contracts exactly, the third except for the trailing metadata hash. I also
recorded the keccak256 of each deployed runtime. Before any test result was trusted, those hashes
were checked again at the pinned block, inside the fork.

### Invariant specification

I wrote 14 invariants, covering custody, replay/uniqueness, pool identity, liveness, token behaviour
and upgradeability. Each one has a formal predicate, the code that enforces it at `file:line`, its
assumptions, and the single most plausible way it breaks. The hypotheses came from this spec.

### Fork-based proof of concept

The Foundry harness forks Arbitrum at a pinned block and runs against the real deployed contracts.
It tests the leading hypothesis end to end, alongside a negative control and a cost boundary test.
All three tests pass, and together they show the hypothesis is not a payable issue: the protocol
operator can recover from the condition within the same transaction, so no non-privileged user's
funds are durably affected. See `evidence/`.

### Duplicate check against prior reviews

I found the target's public third-party security review, archived it (SHA-256 recorded) and mapped
its two disclosed High findings onto the code deployed now. One had already been fixed by a
redesign; the other was a privileged, acknowledged issue. But a substantial set of the review's
findings was not made public, so I could not put a number on the duplicate risk. The decision
records that risk as unknown.

## The decision

The system turned out to be a thin, operator-custodial settlement layer. Only a privileged operator
role could move user collateral, and there was exactly one entry point that an unprivileged caller
could use to change state. The strongest hypothesis reproduced on a fork. Then its own evidence
refuted it: the observed effect could be undone immediately, and it cost the attacker more than it
cost the victim. I rechecked it from the code three times and reached the same conclusion each time,
with the same code citations.

**Result: NO-GO.** No report was submitted. The conclusion was to put the effort into a target with a
better chance of a payable finding.

## Professional posture

- Mainnet was only ever read, and all exploit testing ran on a local fork; no transaction was
  broadcast and no live infrastructure was probed or stressed.
- The target program requires approval before publication. There was no reportable finding, so
  nothing is owed to the program. I have still left the specific mechanism out of this public case
  study.
- An unavailable report and a pruned archive-node result are both recorded as UNKNOWN, with no
  estimate in their place.

## Artifacts

| File | Contents |
|---|---|
| `../../METHODOLOGY.md` | The engineering standard followed throughout |
| `evidence/reproducibility.md` | Toolchain freeze, pinned block, code-hash verification, test output |
| `evidence/ForkPoC.t.sol` | The Foundry fork test (mechanism-neutral excerpt) |
| `private-annex/` | Full findings, invariant spec and unredacted PoC (available on request) |

## Stack used

Solidity · Foundry (forge / cast / anvil) · EVM fork testing · JSON-RPC on-chain forensics ·
EIP-1167 minimal proxies · EIP-1967 proxy slots · ERC-20 accounting · Node.js tooling · Git
