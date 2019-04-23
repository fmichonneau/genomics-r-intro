source("build_lesson.R")

#get_stage("before_install")

get_stage("install") %>%
  add_code_step(remotes::install_github("hadley/requirements"))  %>%
  add_code_step(remotes::install_github("fmichonneau/checker", force = TRUE)) %>%
  add_code_step(remotes::install_cran(requirements:::req_dir("_episodes_rmd"))) %>%
  add_code_step(remotes::install_cran("fs")) %>%
  add_code_step(remotes::install_cran(c("withr", "processx")))

get_stage("deploy") %>%
  add_step(build_lesson())

get_stage("after_deploy") %>%
  add_code_step(
    checker::check_jekyll_links(
      site_root = "_rendered",
      recursive= TRUE,
      only_with_issues = FALSE,
      show_summary = TRUE,
      verbose = TRUE)
  )

if (Sys.getenv("id_rsa") != "") {
  # pkgdown documentation can be built optionally. Other example criteria:
  # - `inherits(ci(), "TravisCI")`: Only for Travis CI
  # - `ci()$is_tag()`: Only for tags, not for branches
  # - `Sys.getenv("BUILD_PKGDOWN") != ""`: If the env var "BUILD_PKGDOWN" is set
  # - `Sys.getenv("TRAVIS_EVENT_TYPE") == "cron"`: Only for Travis cron jobs
  get_stage("before_deploy") %>%
    add_step(step_setup_ssh())

  ## if there is a tag associated with the push or we are in master, the
  ## lesson gets deployed on gh-pages, and rendered by GitHub
  if (ci()$get_branch() == "master" || ci()$is_tag()) {
    get_stage("deploy") %>%
      add_step(step_push_deploy(path = "_rendered", branch = "gh-pages"))
  }

}
