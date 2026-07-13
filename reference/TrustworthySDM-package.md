# TrustworthySDM: Reliability Audits for Species Distribution Models Built on Imperfect Occurrence Data

Species distribution models are routinely fitted to occurrence records
that have been cleaned, filtered or otherwise curated. Cleaning removes
records, and record removal is rarely random with respect to the
environment. 'TrustworthySDM' provides diagnostics that measure what a
quality filter did to the environmental distribution of the training
data, test whether the induced shift can be undone by reweighting, and
report when it cannot. The package is deliberately framework-agnostic:
it operates on a flat table of records and environmental values, needs
no rasters, no background points and no ground truth, and makes no
assumption about the model that will be fitted downstream.

## See also

Useful links:

- <https://kristianmiok.github.io/TrustworthySDM/>

- <https://github.com/KristianMiok/TrustworthySDM>

- Report bugs at <https://github.com/KristianMiok/TrustworthySDM/issues>

## Author

**Maintainer**: Kristian Miok <kristian.miok@fri.uni-lj.si>
