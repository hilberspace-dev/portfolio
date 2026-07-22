# Reproducibility Evidence — ERC-4337 EntryPoint v0.8 Review

Redacted: the defect's file, function and mechanism are withheld (see the case study's disclosure note).
What follows is the verification discipline applied, which is reproducible independently of the finding.

## Scope pin

```
Target       : ERC-4337 Account Abstraction, EntryPoint v0.8 core contracts
Base commit  : 4cbc06072cdc19fd60f285c5997f4f7f57a588de
Severity     : Low (attribution / correctness defect)
Status       : not submitted; not fixed upstream -> mechanism withheld
```

## Environment freeze (captured at proof time)

```
node --version    -> v22.23.1     (matched to the repository's CI-pinned Node 22 via fnm)
                                   Node v24.13.0 reproduces identically as an auxiliary cross-check
yarn --version    -> 1.22.22
npx hardhat --ver -> 2.22.17      (solc 0.8.28, evmVersion cancun)
OS                -> Windows 11 (win32)
```

The toolchain was matched to the project's own CI configuration rather than to whatever happened to be
installed. On Windows the repository's shell wrappers cannot spawn, so tools were invoked directly
(`npx hardhat compile`, not the wrapper script) — a difference worth recording, because a wrapper
returning exit code 0 while the underlying runner never started is a real and easy trap.

## External client, pinned by digest (not by tag)

The second proof required an EVM revision the local toolchain does not implement, so it ran against a
real client. A mutable `:latest` / `:master` tag would make "fully reproducible" a false claim, so the
client is cited by **immutable digest**:

```
image  -> ethpandaops/geth@sha256:ddde359a5e9b54b4cd02d8eee29e7d44e42a9a681effc356d1437a81aee414ef
geth   -> 1.17.5-unstable, commit 85fe2723552f7acd630c754952334ada881da168 (2026-07-20), Prague/Pectra
run    -> docker run --rm -p 8545:8545 \
            ethpandaops/geth@sha256:ddde359a5e9b54b4cd02d8eee29e7d44e42a9a681effc356d1437a81aee414ef \
            --http --http.api eth,net,web3,debug --rpc.allow-unprotected-txs --dev --http.addr 0.0.0.0
chain  -> --dev (chainId 1337); target EVM feature confirmed live before the proof was trusted
```

Practical notes recorded during the run: client flags change across versions (one previously-required
flag had been removed), and `--dev` returns a transient *"transaction indexing is in progress"* error,
so receipts are polled rather than awaited once.

## Why two proofs

| | Proof 1 (local, Cancun) | Proof 2 (real client, Prague) |
|---|---|---|
| Proves | the in-scope control-flow defect | the same result under genuine EVM semantics |
| Limitation | the EVM revision **cannot execute** the delegation feature; the failure is induced by an equivalent stand-in | none for this purpose |
| Labelled as | **approximation** — stated explicitly, not glossed over | authoritative |

Proof 2 asserts on a **unique inner marker** — the deployed helper's own revert string — which
machine-proves the delegated code actually executed, rather than the test reaching the same branch for
an unrelated reason.

## Results

```
Proof 1 (local, no external client):
  ✔ DEFECT  — the affected path reports the wrong value      (94ms)
  ✔ CONTROL — the sibling path reports the correct value     (79ms)
  2 passing (3s)      EXIT_CODE=0

Proof 2 (real Prague client, pinned digest):
  ✔ DEFECT  — same wrong value under genuine EVM semantics  (417ms)
  ✔ CONTROL — sibling path correct                          (168ms)
  2 passing (4s)      EXIT_CODE=0
```

Proof 2 self-skips when the client is unreachable, so it can never silently break the baseline suite.
Recorded explicitly in the report: **a skipped or pending result is NOT evidence — a successful
reproduction must report the expected pass count.**

## Baseline discipline

A proof passing means nothing without a known-good baseline, so the baseline was established and every
failure triaged before the proof was trusted:

```
Full suite                                  -> 123 passing, 2 failing
The 2 failures                              -> `spawn EFTYPE` from a helper launching a shell script;
                                               a Docker/client integration absent on this host,
                                               NOT a code defect
Excluding the two client-dependent files    -> 109 passing, exit 0
Proof run alongside the main EntryPoint suite -> 73 passing
```

That last line matters: the proof was run **in isolation first, then alongside the existing suite**, so
it cannot hide behind pre-existing environmental failures.

## Production-code diff evidence

The proofs add only test files plus one test-only helper contract placed in the repository's test
directory. No in-scope production contract was modified:

```
$ git diff -- contracts/core contracts/utils
(empty)

$ git status --short
?? contracts/test/<test-only helper>.sol
?? test/<proof-1>.test.ts
?? test/<proof-2>.test.ts
```

SHA-256 is recorded for every proof file and **recomputed after any edit** — stale hashes in a report
are a red flag a reviewer will catch.

## Integrity

- No transaction was broadcast to any public network; the external client ran locally in `--dev` mode.
- State-injection helpers were used **only** to reach the in-scope branch, never to shortcut the
  contract's own logic, and that use is disclosed in each test's header comment.
- The finding's severity was assessed **separately** from whether the tests pass. A passing test proves
  a behaviour exists; it does not prove that behaviour is worth money. This one is a Low, and is
  reported as a Low.
