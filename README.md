# atilgandev — Backend Engineer

**Go · PostgreSQL · payment systems · high-integrity software**

Full-stack product delivery, applied computer vision and smart-contract security as additional
technical depth.

📍 Türkiye · ✉️ [Email](mailto:hilberspace@gmail.com) · 🔗 [GitHub profile](https://github.com/hilberspace-dev) · 🇹🇷 [Türkçe özet](README.tr.md)

---

## How I work

Every claim in this portfolio is backed by something a reader can check: a benchmark command, a
public CI run, a written evidence file, or a reproduction recipe, so the projects can speak in
numbers instead of adjectives.

## Engineering standard

→ **[`METHODOLOGY.md`](METHODOLOGY.md)** — the verification standard applied across this portfolio:
freeze the environment, state invariants before testing, require negative controls, preserve the
evidence and report the result even when the correct result is “no finding.”

---

## Projects

### 1. ReconPilot — Payment Reconciliation Engine
→ [case study](projects/03-reconpilot-payment-reconciliation/) · [source, tests & benchmark](https://github.com/hilberspace-dev/reconpilot)

**Demonstrates:** deterministic backend design, financial-data integrity, schema-level constraints, production-grade testing.

*Makes card, marketplace and bank reports agree to the last cent.*

Uses a deterministic three-stage matching chain, seven explicit discrepancy types and four
runtime/database invariants. Its seeded ~50K benchmark checks every match against generator ground
truth: **7/7 types detected, 0 false matches, ~4 s**; CI reruns it on every push. The same static
binary serves REST, HTML, health/readiness and Prometheus metrics, with a one-command seeded Compose
stack.

`Go` `PostgreSQL` `REST` `Prometheus` `Docker Compose` `property-based testing` `testcontainers` `CI`

### 2. Aura — Photoreal 3D Surgical-Preview & Clinic Platform *(private, commercial)*
→ [case study](projects/04-aura-photoreal-3d-clinic-platform/)

**Demonstrates:** solo commercial delivery, full-stack ownership, applied computer vision / ML.

*A patient sees a realistic preview based on their own face; the clinic gets its operations in one
system.*

Built solo across ~800 commits: photoreal head reconstruction from a ~15-second phone capture video
(3D Gaussian Splatting, offline GPU job), an instant in-browser 2.5D preview (~0.4 s), simulation
math in physical millimetres checked against published anthropometric norms, and an outcome
predictor validated against **838 open-access clinical publications**. KVKK/HIPAA-aligned;
payment paths carry property-based and mutation testing. Source is private — the case study covers
scope and non-sensitive measurements only.

`3D Gaussian Splatting` `computer vision` `TypeScript` `React` `Node.js` `mutation testing` `KVKK`

### 3. ERC-4337 EntryPoint v0.8 — Security Review
→ [case study](projects/02-erc4337-entrypoint-review/)

**Demonstrates:** source-level protocol analysis, reproducible proof construction, disclosure discipline.

*In widely trusted, repeatedly inspected infrastructure code, I found a small but genuine
bookkeeping flaw and proved it two independent ways.*

Independent review of heavily audited account-abstraction infrastructure (three public audit
reports ship in its repository). Identified a Low-severity deterministic correctness defect,
isolated it against a sibling code path that handles the equivalent case correctly, and reproduced
it twice — on the local toolchain and on a digest-pinned Prague-enabled client. Not submitted;
mechanism withheld pending an upstream fix.

`Solidity` `Hardhat` `TypeScript` `ERC-4337` `EIP-7702` `Docker-pinned geth`

### 4. Live-Protocol Security Audit (~$16.7M) — a Disciplined NO-GO
→ [case study](projects/01-smart-contract-security-audit/)

**Demonstrates:** hypothesis testing, risk assessment, professional judgment under incentive to overclaim.

*I stress-tested a live system holding ~$16.7M of user funds and proved the suspected weakness was
in fact safe — then reported exactly that.*

On-chain forensics across ~45M blocks, deployed-bytecode verification, a 14-invariant security
specification, and a Foundry proof-of-concept forking mainnet at a pinned block. The leading
vulnerability hypothesis was reproduced on the fork and then refuted by its own evidence; nothing
was submitted.

`Solidity` `Foundry` `EVM fork testing` `JSON-RPC forensics` `Node.js`

---

## Technical skills

| Area | |
|---|---|
| **Backend** | API design, service architecture, data modelling, integration work |
| **Frontend** | Application UI, state management, API integration |
| **Data** | Pipelines, transformation, analysis and reporting |
| **DevOps** | Containerization, CI, environment reproducibility, deployment |
| **AI / ML / CV** | Applied computer vision, 3D reconstruction, model evaluation, LLM API orchestration with fallback design, containerized ML workloads, GPU pipelines |
| **Blockchain** | Solidity, Foundry, EVM internals, proxy patterns, on-chain analysis |
| **Tooling** | Git, Go, Node.js, TypeScript, .NET, PowerShell/Bash |

---

## Working with me

Open to **contract and subcontract work** — independent technical delivery behind an agency or a
lead developer: I take a scoped ticket or spec, work independently, and return it done, with tests
and evidence.

Professional written English for specifications, documentation, tickets and code review; spoken
communication primarily in Turkish.

---

*This is a curated portfolio published after the underlying work was completed. Commit dates
reflect publication and documentation history, not the original development timeline.*
