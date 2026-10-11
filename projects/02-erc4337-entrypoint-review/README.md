[![Türkçe sürüm](https://img.shields.io/badge/Language-T%C3%BCrk%C3%A7e-E30A17?style=for-the-badge)](README.tr.md)

# Case study: ERC-4337 EntryPoint v0.8 security review

> ### Finding: a deterministic correctness defect in `EntryPoint` v0.8 core
>
> | | |
> |---|---|
> | Severity | Low: an attribution/correctness defect; it allows neither theft nor censorship |
> | Prior audits | Three public audit reports ship in the repository |
> | Reproduced | Twice: on the local toolchain, then again under real EIP-7702 semantics on a digest-pinned Prague client |
> | Isolated by | A sibling code path that handles the equivalent case correctly |
> | Upstream status | Still unfixed at time of review |
> | Disclosure | Maintainers contacted on 11 October 2026 ([issue #632](https://github.com/eth-infinitism/account-abstraction/issues/632)); the full report will follow. Not submitted to any program. The mechanism is withheld until the report is posted (see below) |

- Role: independent security researcher
- Target: ERC-4337 Account Abstraction, the `EntryPoint` v0.8 core contracts (open-source, widely deployed)
- Scope commit: `4cbc06072cdc19fd60f285c5997f4f7f57a588de`
- Outcome: one Low-severity deterministic correctness defect, reproduced with two independent proofs of
  concept and written up as a full report (its sections are listed below)

> For non-technical readers: tens of millions of cryptocurrency wallet accounts send their
> transactions through one shared piece of public infrastructure code, ERC-4337's `EntryPoint`. It
> has three published professional audits. I reviewed its version 0.8 independently and found a
> small but real flaw in how it records who was at fault when certain operations fail. It is a
> bookkeeping error that gives no way to steal funds. I reproduced it in two environments, and the
> full mechanism stays private.

> Disclosure status, 11 October 2026. The report is written and ready to send. I contacted the
> maintainers the same day in
> [issue #632](https://github.com/eth-infinitism/account-abstraction/issues/632) and asked whether
> they want the full report there or at a private address. Neither the issue nor this page names the
> file, function or mechanism until the report is posted; the report and both proofs will go
> wherever the maintainers say. The finding has not been submitted to a bug bounty program, and the
> defect is not fixed upstream. Independent confirmation is still outstanding: it needs the
> maintainers' answer, and this page will say so when it happens. Nothing here claims that any
> program reviewed, validated or paid for this finding; full materials are available privately,
> under confidentiality, on request.

## The target

ERC-4337's `EntryPoint` repository ships three public audit reports: two by OpenZeppelin (February
2023 and February 2024) and one by Spearbit, dated 25 March 2025, which covers the v0.8 changes. As
for how widely the code is used:
[Alchemy](https://www.alchemy.com/overviews/what-is-account-abstraction) counts more than 40 million
ERC-4337 smart accounts deployed on Ethereum and layer-2 networks, and on 11 October 2026
[BundleBear](https://www.bundlebear.com/erc4337-overview/all) showed 68.9 million addresses that had
sent at least one user operation. Both figures cover every `EntryPoint` version together; neither
source gives a count for v0.8 alone.

The finding itself is small, a Low-severity attribution/correctness defect and not a theft or
censorship exploit. The rest of this page is about how it was found and proved.

## Method

### The invariant comes from the protocol's own documentation

The project's interface documentation states a property explicitly, and the defect violates it. The
report cites those documented semantics and measures the bug against the protocol's own
specification.

### Isolated by a sibling code path

An analogous path in the same function handles the equivalent case correctly, so the code gets the
same case right in one place and wrong in the other. That looks like an oversight, and it answers
the objection a triager raises most often: that the behaviour was intended.

### Negative control built into the proof

The defect case and the control put the failing operation in the same position, and only the
affected path misreports. The one difference between them is the code path taken, so the harness
cannot be the cause.

### Two execution environments

The local toolchain isolates the control-flow defect, but it stops at an EVM revision that cannot
execute the delegation semantics this path depends on. So a second proof runs against a
digest-pinned Prague client, with a real authorization tuple and a deployed delegate. The inner
revert it sees is the delegate's own message, so the delegated code really executed and the branch
was not reached for some unrelated reason.

### Impact bounded by reachability

The report keeps the primary impact (a deterministic, in-scope correctness defect) apart from the
secondary effects. Those are written with "may". They are explicitly marked as conditional on a
specific off-chain consumer's behaviour. The report also says outright that the defect costs nobody
funds and opens no path to unauthorized execution or direct on-chain censorship. And it documents
the reachability limit: a standards-compliant bundler would filter the failing operation before it
ever reaches a bundle.

## Report structure

The write-up has these sections:

Title · Summary · Severity · Affected commit and in-scope files (supporting files marked
out-of-scope) · Root cause with the vulnerable code and the correct sibling path · Expected vs Actual ·
Observable deterministic defect · Protocol-level impact (primary vs conditional-secondary) ·
Reachability and limitations · Environment freeze · Production-code-diff evidence · How to
reproduce with exact file placement · Exact commands and full verbatim output · Negative control ·
Proof-of-concept sources · Public duplicate-search summary · Suggested remediation with a concrete patch.

The duplicate search covered the three in-repo audit reports, in-code comments, the existing test
suite, upstream issues and pull requests, release notes and the relevant ERC specifications. The
search found no public duplicate. The closest prior art sits in a different location, uses a
different mechanism, and was already fixed in the reviewed tree. Private reports cannot be observed.

## Artifacts

| File | Contents |
|---|---|
| `evidence/reproducibility.md` | Environment freeze, pinned client digest, dual-PoC results, production-diff evidence |
| `../../METHODOLOGY.md` | The engineering standard this engagement followed |
| `private-annex/` | Full report, both PoC test files, and the test-only helper contract (on request, under confidentiality) |

## Stack used

Solidity · Hardhat · TypeScript · ERC-4337 Account Abstraction · EIP-7702 delegation · EVM hardfork
semantics (Cancun vs Prague) · Docker-pinned geth · Foundry-style negative-control test design
