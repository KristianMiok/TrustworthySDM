# Package index

## Audit

Measure what a quality filter did to the environmental distribution of
the training data, before any model is fitted.

- [`audit()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit.md)
  : Audit a quality filter for environmental bias

- [`audit_control()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit_control.md)
  :

  Tuning constants for
  [`audit()`](https://kristianmiok.github.io/TrustworthySDM/reference/audit.md)

- [`print(`*`<sdm_audit>`*`)`](https://kristianmiok.github.io/TrustworthySDM/reference/sdm_audit_methods.md)
  [`summary(`*`<sdm_audit>`*`)`](https://kristianmiok.github.io/TrustworthySDM/reference/sdm_audit_methods.md)
  [`print(`*`<summary.sdm_audit>`*`)`](https://kristianmiok.github.io/TrustworthySDM/reference/sdm_audit_methods.md)
  [`plot(`*`<sdm_audit>`*`)`](https://kristianmiok.github.io/TrustworthySDM/reference/sdm_audit_methods.md)
  : Print, summarise and plot an audit

## Corrections

The two defensible corrections. They move the estimated niche in
opposite directions and bracket the truth between them, which is the
point.

- [`ipw_weights()`](https://kristianmiok.github.io/TrustworthySDM/reference/ipw_weights.md)
  : Inverse-propensity weights for the retained records
- [`trust_weights()`](https://kristianmiok.github.io/TrustworthySDM/reference/trust_weights.md)
  : Trust weights: soft downweighting instead of a hard cut

## Adapters

Bridges from the cleaning tools you already use.

- [`as_quality()`](https://kristianmiok.github.io/TrustworthySDM/reference/as_quality.md)
  : Build a retention indicator from the output of an existing cleaning
  tool

## Simulated data

Occurrence records under four filters, one for each verdict, plus a
symmetric outlier screen that mean-shift diagnostics cannot see.

- [`sim_occ()`](https://kristianmiok.github.io/TrustworthySDM/reference/sim_occ.md)
  : Simulated occurrence records with three different quality filters

## Package

- [`TrustworthySDM`](https://kristianmiok.github.io/TrustworthySDM/reference/TrustworthySDM-package.md)
  [`TrustworthySDM-package`](https://kristianmiok.github.io/TrustworthySDM/reference/TrustworthySDM-package.md)
  : TrustworthySDM: Reliability Audits for Species Distribution Models
  Built on Imperfect Occurrence Data
