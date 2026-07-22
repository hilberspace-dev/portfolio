# Reproducibility Evidence

Every claim in this case study is pinned to a fixed block, a fixed toolchain, and verified bytecode.
This document is the freeze record.

## Chain state pin

```
Network      : Arbitrum One
chainId      : 42161  (verified inside the fork, not assumed)
AUDIT_BLOCK  : 486145712  (0x1cf9feb0)
block hash   : 0x5c6402e5fae2785be603314fa4b8fdd384eabd5971c93780d1a458f96b962de4
block time   : 2026-07-21T09:52:22Z  (unix 1784627542)
access mode  : read-only JSON-RPC (eth_call / eth_getCode / eth_getStorageAt / eth_getLogs)
```

**Archive-node caveat, recorded honestly.** The default public endpoint serves only pruned state and
returned `missing trie node` / `metadata is not found` for historical reads at this block. Two
endpoints were tested and confirmed to serve full archive state at the exact block before being used.
This was verified rather than assumed — a fork against a pruned endpoint silently produces meaningless
results.

## Toolchain freeze

```
forge / cast / anvil : 1.5.1-stable
commit               : b0a9dd9ceda36f63e2326ce530c10e6916f4b8a2
build                : 2025-12-22, maxperf profile
solc                 : 0.8.28   (matches deployed: 0.8.28+commit.7893614a)
optimizer            : enabled, runs = 20000  (matches deployed settings)
host                 : Windows 11, Node.js v24.13.0, Git 2.52.0
```

## Deployed-bytecode verification

Source was taken from verified on-chain sources, not from a similarly-named public repository. The
keccak256 of each deployed runtime was recorded during analysis and then **re-verified at the pinned
block inside the fork** before any test result was trusted:

| Contract | keccak256(runtime) | Verified |
|---|---|---|
| Factory | `0x2b4a7a0d4ed306d36ffa362ff70b55983bc529fc3abcf8b764fc357c91f6eae0` | ✅ match |
| Settlement engine | `0x2695326e79ba8e85f80f440b42e74ed2285531f7502919850cc3ada70f8d51d0` | ✅ match |
| Pool implementation | `0xfc4b3765a3d394c77bbb9a52f160880894f762bd92cf4a89d9c95c8b253a2fa4` | ✅ match |

Source-to-bytecode correspondence was established by an independent verifier that recompiled from the
published Standard-JSON input: two contracts reproduced **exactly** (runtime + creation), the third
matched at runtime **modulo the trailing metadata hash** — a distinction recorded explicitly rather than
rounded up to "verified".

All 38,485 deployed clones were confirmed byte-for-byte as EIP-1167 minimal proxies delegating to the
verified implementation:

```
363d3d373d3d3d363d73 <implementation> 5af43d82803e903d91602b57fd5bf3
```

## Test execution

```
$ forge test --fork-url <archive-endpoint> --fork-block-number 486145712 -vv

Compiling 19 files with Solc 0.8.28
Solc 0.8.28 finished in 2.27s
Compiler run successful!

Ran 3 tests for test/ForkPoC.t.sol
[PASS] test_minimumCost_and_zeroRejected()            (gas: 352950)
[PASS] test_negativeControl_noBurn_withdrawalSucceeds() (gas: 325636)
[PASS] test_hypothesis_blocks_then_operator_recovers()  (gas: 420165)

Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 4.47s
```

**Reading the result correctly.** The tests pass — and that is precisely what *disproves* the
hypothesis. Test 3 establishes the effect exists, then establishes that the protocol operator reverses
it within the same transaction, so no honest party is durably affected. Test 2 is the negative control:
without the attacker's action the same operation succeeds, proving the effect came from the claimed root
cause and not the harness. Test 1 bounds the attacker's minimum cost.

A passing test proves a behaviour exists. It does not prove that behaviour is worth money — severity was
assessed separately, and the conclusion was that it is not reportable.

## Integrity of the work product

- Production sources were never modified: a diff over the verified-source directories is empty; only
  test and documentation files were added.
- Each proof file's SHA-256 is recorded, and recomputed after any edit.
- The archived third-party security review is stored with its SHA-256 so its contents cannot be
  silently altered.
- No transaction was ever broadcast to any live network. No live infrastructure was probed.
