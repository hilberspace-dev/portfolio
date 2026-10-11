[![Türkçe sürüm](https://img.shields.io/badge/Language-T%C3%BCrk%C3%A7e-E30A17?style=for-the-badge)](README.tr.md)

# Case study: smart-contract security audit (Immunefi bug bounty, Arbitrum One)

- Role: independent security researcher
- Target: Variational, a public Immunefi bug bounty program on Arbitrum One (chainId 42161)
- Duration: 2 focused work sessions
- Outcome: **NO-GO.** No qualifying vulnerability; nothing submitted.

> For non-technical readers: a platform whose settlement logic runs in smart contracts, with about
> $16.7 million of user funds in two operator wallets, had a public standing offer to pay anyone who
> found a way to break it. I investigated the most promising weakness end-to-end and built a working
> simulation against the platform's real, live configuration. The simulation showed that the observed
> condition was recoverable within the same transaction and did not create a qualifying
> vulnerability. I documented the refutation and stopped the review without submitting a report.

## Why a "nothing found" case study

The engagement ended in a negative result, and this page is about how that result was reached. On a
heavily audited target a false positive can eat review time and end up as a weak submission, so
knowing where to stop is part of the job. The outcome was a decision to stop, with executable
evidence for the reason.

## What the engagement required

1. Establish exactly what the program pays for, and freeze those rules with a timestamp.
2. Pin the on-chain state to a single block so every later claim is reproducible.
3. Obtain the source of the exact deployed contracts. A public repo with a similar name does not count.
4. Model the system's money flows, trust boundaries and security invariants before hunting.
5. Test the strongest hypothesis with a runnable proof, and accept the result either way.

## Selected technical work

### On-chain forensics (read-only JSON-RPC)

Two of the three assets named in the bounty scope turned out to be externally-owned accounts with no
contract code: wallets holding ~11.7M and ~5.0M USDC respectively. That left a single deployed
contract, plus the minimal-proxy clones it deploys, as the real attack surface. Enumerating
contract-creation events across ~45M blocks found 38,485 deployed clones; each one was verified
byte-for-byte as an EIP-1167 minimal proxy pointing at one implementation.

### Source provenance

I retrieved the verified sources for all three code-bearing contracts, recorded the compiler settings
(solc 0.8.28, optimizer runs=20000) and confirmed that the deployed runtime bytecode matched the
published source. The keccak256 of each deployed runtime was recorded, then checked again at the
pinned block inside the fork before any test result was trusted.

### Invariant specification

I wrote 14 invariants covering custody, replay/uniqueness, pool identity, liveness, token behaviour
and upgradeability. Each has a formal predicate, the enforcing code at `file:line`, its assumptions
and the single most plausible way it breaks. The hypotheses were derived from this spec.

### Fork-based proof of concept

The Foundry harness forks Arbitrum at a pinned block and runs against the real deployed contracts. It
tests the leading hypothesis end-to-end, with a negative control and a cost boundary test. All three
tests pass, and together they prove the hypothesis is not a payable issue: the protocol operator can
recover from the condition within the same transaction, so no non-privileged user's funds are durably
affected. See `evidence/`.

### Duplicate check against prior reviews

I located and archived the target's public third-party security review (SHA-256 recorded) and mapped
its two disclosed High findings against the currently deployed code. One had already been remediated
by redesign; the other was a privileged/acknowledged issue. A substantial set of the review's findings
was not publicly disclosed, so the duplicate risk could not be quantified. The decision records that
risk as unknown.

## The decision

The system turned out to be a thin, operator-custodial settlement layer. Only a privileged operator
role could move user collateral, and there was exactly one unprivileged entry point that mutates
state. The most promising hypothesis was reproduced on a fork and then refuted by its own evidence:
the observed effect was recoverable immediately, and it cost the attacker more than the victim.

The hypothesis was rechecked three times from the code, and each check reached the same conclusion
with the same code citations.

**Result: NO-GO.** No report was submitted. The conclusion was to put the effort into a target with a
structurally better payoff profile.

## Professional posture

- All access to mainnet was read-only. No transaction was ever broadcast, all exploit testing ran on
  a local fork, and no live infrastructure was probed or stressed.
- The target program requires approval before publication. The engagement produced no reportable
  finding, so nothing is owed to the program; even so, the specific mechanism examined is left out
  of this public case study.
- An unavailable report and a pruned archive-node result are recorded as UNKNOWN. Neither was
  estimated.

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
