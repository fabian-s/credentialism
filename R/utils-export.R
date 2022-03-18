export_uni2work <- function(
  results,
  outfile = paste0("uni2work-export-", Sys.Date(),".csv")
) {
  export <- results |>
    filter(grade != "invalid") |>
    mutate(
      # uni2work needs "5.0" etc, not just 5
      grade = formatC(as.numeric(as.character(grade)), format = "f", digits = 1)
    ) |>
    select(matriculation, grade) |>
    rename(`exam-result` = grade)
  message("writing to file ", outfile, ".\n")
  write.csv(export, file = outfile,
              row.names = FALSE,
              quote = FALSE)
  invisible(export)
}
