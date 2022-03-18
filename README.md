---
title: "Semi-automated grading workflow"
output: html_document
editor_options: 
  markdown: 
    wrap: 80
---



This is not an actual R package, just some utility functions and this Rmd file.

The intended use is for you to modify this Rmd-file so it fits your exam, run the chunks interactively, and then paste the relevant outputs into your lecture homepage and the template spreadsheet "Notenliste"-files for the grades.


## Import grading information

Assumes that student info was collected from moodle via the standard form for "Klausuranmeldung" and that the resulting sheet as exported from moodle also contains the points (or grades) the students achieved.

**For processing further, your `results`-table needs at least the following columns:**

-   `matriculation`: "Matrikelnummer"
-   `vn`, `nn`: surname, family name
-   `po`, `anderePO`: subjects, as exported from moodle's "Klausuranmeldung"
-   `points`: achieved points  --  
  **NB:** 0 points are assumed to mean invalidated / "entwertet" or no-show if you have participants that actually got 0 points, just set them to 0.1, e.g...
-   (`grade`, if not generated automatically from `points`, see below)

E.g. for the fake spreadsheet included in the package:


```r
results <- 
  rio::import(system.file("extdata", "testtest.csv", package = "credentialism")) 
head(results)
```

```
##   Matrikelnummer    vn              nn             po Gesamt andere PO
## 1         120798   Goy       Xukuraqus   Ethnobotanik     28        NA
## 2         112259   Bir   Hahogumeqafub   Ethnobotanik     35        NA
## 3         154577  Kunu Hamahenanidajaj  Finnougristik     57        NA
## 4         141328   Hej     Dekihuqecoy Agrartheologie     25        NA
## 5         106914 Guhas    Xabelesinetu Agrartheologie     64        NA
## 6         140726  Faxa       Yonayeyuq Agrartheologie     48        NA
```

```r
results <- results |> 
  dplyr::select(c(Matrikelnummer, vn, nn,  po, Gesamt, `andere PO`)) |> 
  dplyr::rename("matriculation" = Matrikelnummer, 
                "points" = Gesamt)
pillar::glimpse(results)
```

```
## Rows: 21
## Columns: 6
## $ matriculation [3m[38;5;246m<int>[39m[23m 120798, 112259, 154577, 141328, 106914, 140726, 139899, 156298, 134927, 132477, 121289, 137457, 10…
## $ vn            [3m[38;5;246m<chr>[39m[23m "Goy", "Bir", "Kunu", "Hej", "Guhas", "Faxa", "Qud", "Fuwa", "Ciyi", "Pav", "Hije", "Yaju", "Vaviq…
## $ nn            [3m[38;5;246m<chr>[39m[23m "Xukuraqus", "Hahogumeqafub", "Hamahenanidajaj", "Dekihuqecoy", "Xabelesinetu", "Yonayeyuq", "Gubi…
## $ po            [3m[38;5;246m<chr>[39m[23m "Ethnobotanik", "Ethnobotanik", "Finnougristik", "Agrartheologie", "Agrartheologie", "Agrartheolog…
## $ points        [3m[38;5;246m<int>[39m[23m 28, 35, 57, 25, 64, 48, 47, 63, 24, 0, 0, 27, 27, 35, 66, 73, 31, 34, 38, 51, 44
## $ `andere PO`   [3m[38;5;246m<lgl>[39m[23m NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
```


## Set grades

Set maximum number of points and adjust recommended grading scheme
(*Notenstufen*) if necessary -- e.g. `niceness = 0.01`  would decrease the
point percentages needed for a given grade by 1 \%.


```r
MAX_POINTS <- 75 #! change this if you rerun for a different exam
(scheme <- set_grading_scheme(max_points = MAX_POINTS, niceness = .0))
```

```
##  4.0  3.7  3.3  3.0  2.7  2.3  2.0  1.7  1.3  1.0 
## 32.5 34.5 36.5 41.5 45.5 50.5 54.5 59.5 62.5 66.5
```

Then compute grades and identify borderline cases
(skip this if your table already contains grades and not just points, but **make sure
`scheme` and `MAX_POINTS` are set correctly**):

```r
results <- results |> 
  dplyr::mutate(
    grade = grade_points(points, scheme = scheme),
    # who failed by 2 pts or less?
    almost_but_no_cookie = (points < scheme[1]) & (points > (scheme[1] - 2)))
pillar::glimpse(results)
```

```
## Rows: 21
## Columns: 8
## $ matriculation        [3m[38;5;246m<int>[39m[23m 120798, 112259, 154577, 141328, 106914, 140726, 139899, 156298, 134927, 132477, 121289, 137…
## $ vn                   [3m[38;5;246m<chr>[39m[23m "Goy", "Bir", "Kunu", "Hej", "Guhas", "Faxa", "Qud", "Fuwa", "Ciyi", "Pav", "Hije", "Yaju",…
## $ nn                   [3m[38;5;246m<chr>[39m[23m "Xukuraqus", "Hahogumeqafub", "Hamahenanidajaj", "Dekihuqecoy", "Xabelesinetu", "Yonayeyuq"…
## $ po                   [3m[38;5;246m<chr>[39m[23m "Ethnobotanik", "Ethnobotanik", "Finnougristik", "Agrartheologie", "Agrartheologie", "Agrar…
## $ points               [3m[38;5;246m<int>[39m[23m 28, 35, 57, 25, 64, 48, 47, 63, 24, 0, 0, 27, 27, 35, 66, 73, 31, 34, 38, 51, 44
## $ `andere PO`          [3m[38;5;246m<lgl>[39m[23m NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
## $ grade                [3m[38;5;246m<fct>[39m[23m 5.0, 3.7, 2.0, 5.0, 1.3, 2.7, 2.7, 1.3, 5.0, invalid, invalid, 5.0, 5.0, 3.7, 1.3, 1.0, 5.0…
## $ almost_but_no_cookie [3m[38;5;246m<lgl>[39m[23m FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
```

```r
# be merciful to these folks who just missed the cut-off...?
dplyr::filter(results, almost_but_no_cookie)
```

```
##   matriculation     vn              nn           po points andere PO grade almost_but_no_cookie
## 1        116242 Kofuru Pipavehavavasiy Ethnobotanik     31        NA   5.0                 TRUE
```

See `utils-grading.R` for function details.

## Summarize & publish (pseudonymous) results

`summarize_grades` and `publish_grades` both put their output on the
clipboard if you run them in `interactive()`-mode.  
These outputs are formatted as an HTML table,
so you can paste them directly into Moodle's HTML editor... :)


```r
# without invalid / no-show exams (by default):
summarized <- 
  summarize_grades(results, scheme = scheme, 
                   max_points = MAX_POINTS) #, exclude_invalid = TRUE)
```

```
## Joining, by = "grade"
## HTML table copied to your clipboard.
```

```r
summarized |> knitr::kable()
```



|Grade |    %|Points  |
|:-----|----:|:-------|
|1.0   |  5.3|66.5-75 |
|1.3   | 15.8|62.5-66 |
|2.0   |  5.3|54.5-59 |
|2.3   |  5.3|50.5-54 |
|2.7   | 10.5|45.5-50 |
|3.0   |  5.3|41.5-45 |
|3.3   |  5.3|36.5-41 |
|3.7   | 10.5|34.5-36 |
|4.0   |  5.3|32.5-34 |
|5.0   | 31.6|0-32    |

```r
# all:
summarized_all <- 
  summarize_grades(results, scheme = scheme, max_points = MAX_POINTS, exclude_invalid = FALSE)
```

```
## Joining, by = "grade"
## HTML table copied to your clipboard.
```

```r
summarized_all |> knitr::kable()
```



|Grade   |    %|Points  |
|:-------|----:|:-------|
|1.0     |  4.8|66.5-75 |
|1.3     | 14.3|62.5-66 |
|2.0     |  4.8|54.5-59 |
|2.3     |  4.8|50.5-54 |
|2.7     |  9.5|45.5-50 |
|3.0     |  4.8|41.5-45 |
|3.3     |  4.8|36.5-41 |
|3.7     |  9.5|34.5-36 |
|4.0     |  4.8|32.5-34 |
|5.0     | 28.6|0-32    |
|invalid |  9.5|-       |

Pseudonymous results with matriculation numbers for your moodle page or public notices:


```r
public <- publish_grades(results, scheme = scheme, max_points = MAX_POINTS)
```

```
## HTML table copied to your clipboard.
```

```r
public |> knitr::kable()
```



| Matrikelnummer|Grade   | Points|
|--------------:|:-------|------:|
|         105621|3.7     |     35|
|         106914|1.3     |     64|
|         107662|4.0     |     34|
|         109735|5.0     |     27|
|         110417|3.3     |     38|
|         112259|3.7     |     35|
|         116242|5.0     |     31|
|         117454|3.0     |     44|
|         117853|1.3     |     66|
|         120798|5.0     |     28|
|         121289|invalid |      0|
|         132477|invalid |      0|
|         134927|5.0     |     24|
|         136639|1.0     |     73|
|         137457|5.0     |     27|
|         139899|2.7     |     47|
|         140726|2.7     |     48|
|         141328|5.0     |     25|
|         150027|2.3     |     51|
|         154577|2.0     |     57|
|         156298|1.3     |     63|

```r
# without no-shows / invalidated:
public_all <- results |>  dplyr::filter(grade != "invalid") |> 
  publish_grades(scheme = scheme, max_points = MAX_POINTS)  
```

```
## HTML table copied to your clipboard.
```

```r
public_all |> knitr::kable()
```



| Matrikelnummer|Grade | Points|
|--------------:|:-----|------:|
|         105621|3.7   |     35|
|         106914|1.3   |     64|
|         107662|4.0   |     34|
|         109735|5.0   |     27|
|         110417|3.3   |     38|
|         112259|3.7   |     35|
|         116242|5.0   |     31|
|         117454|3.0   |     44|
|         117853|1.3   |     66|
|         120798|5.0   |     28|
|         134927|5.0   |     24|
|         136639|1.0   |     73|
|         137457|5.0   |     27|
|         139899|2.7   |     47|
|         140726|2.7   |     48|
|         141328|5.0   |     25|
|         150027|2.3   |     51|
|         154577|2.0   |     57|
|         156298|1.3   |     63|

## Export official grade tables

### Export for *new* Statistik PO 2021


```r
results_new <- dplyr::mutate(results, 
                             grade_num = as.numeric(as.character(grade)) * 100, 
                             geschl = "",
                             abschl = "",
                             Stg = "",
                             pversuch = "",
                             pvermerk = "",
                             email = "") |> 
  dplyr::rename(mtknr = "matriculation", 
                nachname = "nn",
                vorname = "vn",
                poversion = "po",
                bewertung = "grade_num") |> 
  dplyr::select(mtknr, nachname, vorname, geschl, abschl, Stg, 
                poversion, pversuch, pvermerk, bewertung, email)
```

```
## Warning in mask$eval_all_mutate(quo): NAs introduced by coercion
```

```r
results_new |>  
  print.data.frame(row.names = FALSE, max = nrow(results_new)) |> 
  clipr::write_clip() 
```

```
##   mtknr  nachname vorname geschl abschl Stg    poversion pversuch pvermerk bewertung email
##  120798 Xukuraqus     Goy                   Ethnobotanik                         500      
##  [ reached 'max' / getOption("max.print") -- omitted 20 rows ]
```

```r
# the last command puts the table on the clipboard, 
# so you can <ctrl-v> it directly into the template .xls-file
```

Actually need to generate separate tables for each subject, like so:

```r
for (this_po in unique(results_new$poversion)) {
  message("####\n grades for ", this_po, ":\n")
  results_new |> dplyr::filter(poversion == this_po) |> 
    print.data.frame(row.names = FALSE, max = nrow(results_new)) |> 
    clipr::write_clip()  
  readline("ready for next group? ")
}
```

### Export for Statistik PO 2010 etc

not automated, sorry.

### Export to Uni2Work

CS majors can get their grades from [uni2work](https://uni2work.ifi.lmu.de),
maths majors (theoretically) as well (... I think?),
the files to upload there expect this format:

<img src="https://github.com/fabian-s/credentialism/blob/main/README_files/figures/paste-809C5790.png"/>


```r
results_cs_maths <- dplyr::filter(results, 
                                  po != "Statistik als HF")
export_uni2work(results_cs_maths, outfile = "demo-uni2work.csv")
```

```
## writing to file demo-uni2work.csv.
```

Now log in at [uni2work](https://uni2work.ifi.lmu.de), create an "external exam", 
navigate to its "Participants" tab & upload this CSV file. All done. 
