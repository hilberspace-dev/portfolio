# Serhat Atılgan | Backend engineering

[Türkçe](README.tr.md) · [GitHub](https://github.com/hilberspace-dev)

I build backend systems in Go, PostgreSQL and TypeScript for e-commerce and fintech teams. Most of
my work is payment reconciliation and API integration, and I also take over the maintenance of
existing applications. I live in Türkiye and work in Turkish and English.

## Main project: ReconPilot

ReconPilot is a Go/PostgreSQL application that imports PSP reports, bank statements and marketplace
settlements. It applies exact, tolerant and group matching, then classifies whatever is left over.
Runtime checks reject a result that leaves an input unaccounted for, or one that puts a transaction
in more than one match group.

The public repository has the CLI, the HTTP service, the HTML report, the tests and a seeded
synthetic benchmark. The benchmark compares the matches with the groups the generator intended; here
is its verification panel for seed 1, about 49,000 transactions:

[![ReconPilot verification panel: 7/7 injected discrepancy types detected, 0 false matches, 0 intended pairs or groups missed](https://raw.githubusercontent.com/hilberspace-dev/reconpilot/main/docs/verification-panel-top.png)](https://github.com/hilberspace-dev/reconpilot)

Since the benchmark has never run on customer data, it says nothing about accuracy there. CI repeats
it on GitHub's runners on every push, and you can check the claim without installing anything: the
repository opens in Codespaces with the benchmark running.

[Source and run instructions](https://github.com/hilberspace-dev/reconpilot) ·
[Case study](projects/03-reconpilot-payment-reconciliation/)

## Supporting work

I do not sell the two areas below as services. They are here because the method is the one I use on
backend work: a pinned environment and a written claim, plus a runnable check that can say no.

### Security reviews (Solidity)

- [ERC-4337 EntryPoint](projects/02-erc4337-entrypoint-review/): a correctness finding that I
  assessed internally as Low severity, with reproductions recorded locally and on a client. The
  maintainers were contacted on 11 October 2026
  ([issue #632](https://github.com/eth-infinitism/account-abstraction/issues/632)) and the full
  report follows there; the mechanism and proofs stay private until it is posted. There is no
  independent confirmation yet, and the finding has not been submitted to a bounty programme.
- [Smart-contract investigation](projects/01-smart-contract-security-audit/): I tested a hypothesis
  against a pinned local fork and rejected it, because the operator could recover from the observed
  condition. No finding was submitted. The public excerpt shows how the test is built, but you cannot
  run it as a reproduction.

### AURA (research prototype)

AURA is my private research prototype. It combines browser-based facial measurement and surgical
preview with clinic workflows, and I lead technical design and review on the web application and
API as well as the research code. So far it has no users or revenue, and nobody independent has
validated it on living faces. What the preview shows is a proposed plan; it does not predict the
result of surgery.

The case study shows the pre-registered benchmark of 27 September 2026 as a chart, with the bars it
was measured against. It also quotes a support note from an ENT surgeon and a reply from a Birmingham
professor, and says what neither statement claims.

[Project scope and current limits](projects/04-aura-photoreal-3d-clinic-platform/)

## Working together

I take fixed-scope engagements, and the initial call and assessment are free. When a problem needs
investigating first, a paid discovery phase ends with a diagnosis and a proposed scope
(deliverables, acceptance criteria, timeline) before any implementation starts. Payment follows
delivery milestones, and if the first milestone fails the agreed criteria I do not invoice it.

Handover includes the source with its tests and operating instructions, and a session with the
receiving team if we agreed on one. Client work is subject to confidentiality; client source and
data are kept out of this portfolio.

[Delivery process](DELIVERY-METHODOLOGY.md) ·
[Security review method](METHODOLOGY.md)

## Contact

[hilberspace@gmail.com](mailto:hilberspace@gmail.com) ·
[WhatsApp](https://wa.me/905431064025) · [+90 543 106 40 25](tel:+905431064025)

Please tell me the problem and the current stack, what you expect delivered and by when, and any
access constraints. Use anonymised samples for an initial data review.
