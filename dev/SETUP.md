# Setup — one time

## 0. Fill these in first
`DESCRIPTION`: check the email. Add your ORCID:
```
person("Kristian", "Miok", , "your.email@fri.uni-lj.si",
       role = c("aut", "cre"),
       comment = c(ORCID = "0000-0000-0000-0000"))
```

## 1. Check the name is free on CRAN
```bash
Rscript -e 'install.packages("available"); available::available("TrustworthySDM")'
```

## 2. Create an EMPTY repo on github.com
Name: `TrustworthySDM`. No README, no .gitignore, no licence — this repo already has them.

## 3. Push
```bash
cd ~/Desktop/TrustworthySDM
git init
git add .
git commit -m "TrustworthySDM 0.1.0: audit module"
git branch -M main
git remote add origin https://github.com/KristianMiok/TrustworthySDM.git
git push -u origin main
```

## 4. Turn on the documentation site
The `pkgdown` workflow runs on push and writes a `gh-pages` branch.
After the first run finishes (Actions tab, ~5 min):

GitHub → Settings → Pages → Source: **Deploy from a branch** → Branch: **gh-pages** / **(root)** → Save.

Site appears at https://kristianmiok.github.io/TrustworthySDM/

## 5. DOI (do this before you cite the package anywhere)
zenodo.org → log in with GitHub → Settings → enable the `TrustworthySDM` repo.
Then on GitHub: Releases → Create release → tag `v0.1.0`. Zenodo mints the DOI.

---

# Working on it

R lives in the terminal, not in PyCharm. From the package root:

```bash
Rscript -e 'roxygen2::roxygenise()'          # after editing any roxygen comment
Rscript -e 'testthat::test_local()'          # run the tests
R CMD build . && R CMD check --no-manual TrustworthySDM_0.1.0.tar.gz
```

If you want the site locally (optional — CI builds it anyway):
```bash
Rscript -e 'pkgdown::build_site()'
```

`man/*.Rd` and `NAMESPACE` are **generated**. Never edit them by hand; edit the
roxygen comments above each function and re-run `roxygenise()`.

---

## Previewing the site locally

The `docs/` folder in this zip is a **fully built pkgdown site**. Just open

    docs/index.html

in a browser. That is exactly what GitHub Pages will serve.

`docs/` is in `.gitignore` on purpose: the `pkgdown.yaml` GitHub Action rebuilds
it on every push and deploys to the `gh-pages` branch. You never commit it.

To rebuild it yourself after editing the README or the roxygen docs:

    R -e 'pkgdown::build_site()'

## Changing the logo

Four hex variants are in `dev/logo/` (`hex_A` .. `hex_D`). `hex_D` is currently
mounted. To swap in another one:

    R -e 'magick::image_write(magick::image_read("dev/logo/hex_B.svg"), "man/figures/logo.png")'

or regenerate from source with `dev/logo/hexgen.py` + `variants.py`.
