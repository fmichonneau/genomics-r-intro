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

CheckLinks <- R6::R6Class(
     "CheckLinks", inherit = TicStep,
     public = list(
       run = function() {
         ## While build_lesson() merely copies the content of the repo into a
         ## new folder that GitHub picks up to render (so the dynamically
         ## generated links such as "Edit on GitHub" are functional), here we
         ## actually need to generate the website so we can test the links.

         timeout <- 30 * 60
         timeout <- as.difftime(timeout, units = "secs")
         deadline <- Sys.time() + timeout

         bundle_install <- withr::with_dir("_rendered", {
           processx::run("bundle", "install")
         })
         message(bundle_install$stdout)

         jkyl <- withr::with_dir("_rendered", {
           processx::process$new(
             "bundle",
             c("exec", "jekyll", "serve", "--port", "4002"),
             stdout = "|", stderr = "|")
         })
         message("is jekyll alive?:", as.character(jkyl$is_alive()))

         while (jkyl$is_alive() && (now <- Sys.time()) < deadline) {
           poll_time <- as.double(deadline - now, units = "secs") * 1000
           jkyl$poll_io(as.integer(poll_time))
           lines <- jkyl$read_output_lines()
           message(cat(lines, sep = "\n"))
           if (any(grepl("server running", lines, ignore.case = TRUE))) {
             message("Jekyll is running just fine.")
             break
           } else {
             message("jekyll isn't running quite yet.")
           }
         }

         on.exit(jkyl$kill(), add = TRUE)

         res_jekyll <- checker::check_links(
           "_rendered/_site",
           root_dir = "http://localhost:4002",
           recursive= TRUE,
           only_with_issues = FALSE,
           show_summary = TRUE
         )

       })
)

## system("cd _rendered && rvm 2.5.1 do ruby -S jekyll build")

## ## ignore JS file not included as part of rmarkdown
## ## ignore email addresses
## ## ignore embedded images
## link_status <- system("linkchecker --ignore-url=external.+js --ignore-url=^mailto: --ignore-url=^data: --no-warnings  --file-output=csv/link_res.csv _rendered/_site")
## message("linkchecker exit code: ", link_status)

## ## Because URLs can contain #, we first need to remove the commented
## ## lines in the generated CSV file. We can't rely on the comment
## ## argument of the read_delim function, see
## ## https://github.com/tidyverse/readr/issues/828
## csv_links_files <- readLines("link_res.csv")
## writeLines(csv_links_files[grepl("^[^#]", csv_links_files)],
##   con = "link_res_clean.csv",
##   sep = "\n")

## ## write output to CSV file and check error codes
## ## stop only for 404s
## res_links <- readr::read_delim("link_res_clean.csv", delim = ";")
## unique(res_links$result)
## res_404 <- grepl("^404|^gaierror", res_links$result)
## other_errors <- grepl("error", res_links$result, ignore.case = TRUE)
## if (any(other_errors))
##            warning("These links might be problematic: \n",
##                    format_url_errors(res_links, other_errors))
##          if (any(res_404))
##            stop("Some links are broken (check log to inspect): \n",
##                 format_url_errors(res_links, res_404))
##          })
## )

check_links <- function() {
  CheckLinks$new()
}
