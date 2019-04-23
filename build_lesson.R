library(tic)

BuildLesson <- R6::R6Class(
  "BuildLesson", inherit = TicStep,
  public = list(
    run = function() {
      build_status <- system("make clean-rmd; make lesson-md")
      if (build_status > 0)
        stop("Error during building process")

      if (inherits(ci(), "TravisCI")) file.remove(".gitignore")

      system("mkdir  _rendered")
      system("cp -r \`ls -A | grep -v '.git' | grep -v '_rendered' | grep -v '_site'\` _rendered")


    })
)

build_lesson <- function() {
  BuildLesson$new()
}
