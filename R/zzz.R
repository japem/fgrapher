# Contains objects to be loaded when the package loads

.onLoad <- function(libname, pkgname) {

  # FG style colors
  fg_green = "#50AE26"
  assign("fg_green", fg_green, envir = .GlobalEnv)
  fg_blue = "#336699"
  assign("fg_blue", fg_blue, envir = .GlobalEnv)
  fg_orange = "#FBAC26"
  assign("fg_orange", fg_orange, envir = .GlobalEnv)
  fg_red = "#CE4A49"
  assign("fg_red", fg_red, envir = .GlobalEnv)
  fg_graph_highlight = "#FCC531"
  assign("fg_graph_highlight", fg_graph_highlight, envir = .GlobalEnv)

  # Strike zone coordinates
  sz_bot = 1.7544
  assign("sz_bot", sz_bot, envir = .GlobalEnv)
  sz_top = 3.4248
  assign("sz_top", sz_top, envir = .GlobalEnv)
  sz_left = -.7083333
  assign("sz_left", sz_left, envir = .GlobalEnv)
  sz_right = .7083333
  assign("sz_right", sz_right, envir = .GlobalEnv)

  #fangraphs ggplot2 theme

  fgt = ggplot2::theme(panel.background=element_rect(color="lightgrey",fill="white"),
                       axis.title = element_text(family="Lato"),
                       axis.text = element_text(family="Lato"),
                       legend.title = element_text(family="Lato"),
                       legend.text = element_text(family="Lato"),
                       legend.background = element_rect(fill="white"),
                       legend.key = element_rect(fill="white"),
                       plot.title = element_text(family="Lato"),
                       panel.grid.major=element_line(size=.1,color="lightgrey"),
                       panel.grid.minor=element_line(size=0)
  )

  assign("fgt", fgt, envir = .GlobalEnv)

}
