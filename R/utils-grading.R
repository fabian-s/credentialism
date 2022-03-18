# compute the required points for the different grades:
set_grading_scheme <- function(
  max_points, # max. possible points
  # recommended percentages of <max_points> to achieve a grade:
  percentages = c("4.0" = .44, "3.7" = .47, "3.3" = .50, "3.0" = .56, "2.7" = .62, "2.3" = .68,
                  "2.0" = .74, "1.7" = .80, "1.3" = .85, "1.0" = .90),
  #lower percentages by <niceness> to make grading more lenient (or more strict if < 0)
  niceness = 0.00
) {
  floor(max_points * (percentages - niceness)) -.5
}

# return an ordered factor with the grades corresponding to <points> according to <scheme>
grade_points <- function(
  points, # numeric vector
  scheme  # lower boundaries as output from <set_grading_scheme>
) {
  # 0 points are always categorized as invalid / "entwertet"
  cut(points,
      c(-.01, 0.1, scheme, Inf), right = FALSE,
      labels = c("invalid", "5.0", "4.0", "3.7", "3.3", "3.0", "2.7", "2.3",
                 "2.0", "1.7", "1.3", "1.0"))
}

# puts an HTML table of the grade distribution on the system clipboard
# (and returns it invisibly)
#' @importFrom tibble tibble
#' @import dplyr
#' @importFrom knitr kable
#' @importFrom clipr write_clip
summarize_grades <- function(
  results,  #dataframe containing "grade"-column with output from <grade_points()>
  scheme,  #output from make_grading_scheme
  max_points, # max. possible points
  exclude_invalid = TRUE
) {
  pointranges <- tibble::tibble(
    grade = levels(results$grade),
    Points = paste0(c("", 0, scheme), "-", c("", scheme - .5, max_points)))
  if (exclude_invalid) {
    pointranges <- pointranges[-1, ]
    results <- dplyr::filter(results, grade != "invalid")
  }
  summary_grades <-
    results %>%  dplyr::group_by(grade) %>%
    dplyr::summarise(`%` = n(),
              `%` = round(`%` / nrow(results) * 100, 1)) |>
    dplyr::left_join(pointranges) |>
    dplyr::arrange(grade) |>
    dplyr::rename("Grade" = grade)

  if (interactive()) {
    summary_grades |> knitr::kable(format = "html") |> clipr::write_clip()
    message("HTML table copied to your clipboard.\n")
  }
  invisible(summary_grades)
}

# puts an HTML table of grades, total points, and matriculation #s on the system clipboard
# (and returns it)
publish_grades <- function(
  results,  #dataframe containing <grade> with output from <grade_from_points()>
          #   and <matriculation>
  scheme,  #output from make_grading_scheme
  max_points # max. possible points
) {
  output <- results %>% dplyr::select(matriculation, grade, points) |>
    dplyr::arrange(matriculation) |>
    dplyr::rename("Matrikelnummer" = matriculation,
                  "Grade" = grade,
                  "Points" = points)
  if (interactive()) {
    output |>  knitr::kable(format = "html", align = c("l", "c", "r")) |>
      clipr::write_clip()
    message("HTML table copied to your clipboard.\n")
  }
  invisible(output)
}
