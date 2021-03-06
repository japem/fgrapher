#' Graph strike zone
#' 
#' @param batter Defaults to "all". Input either a name or FanGraphs playerid.
#' @param pitcher Defaults to "all". Input either a name or FanGraphs playerid.
#' @param count Ball-strike count. Defaults to all. Input x instead of a number to get all counts; e.g. "3-x" for all 3-ball counts
#' @param startdate Start date. Format yyyy-mm-dd. Defaults to 2016-01-01.
#' @param enddate End date. Format yyyy-mm-dd. Defaults to 2017-01-01.
#' @param year The year. Overrides startdate and enddate. Can only be one full year -- use startdate and enddate for full control over date range.
#' @param stand Batter handedness. Defaults to both.
#' @param throws Pitcher handedness. Defaults to both.
#' @param size Size of the points on the graph.
#' @param heatmap Defaults to FALSE.
#' @param pitchtypes Defaults to all. To include multiple pitch types, create an array: c("Four-seam fastball","Changeup","Breaking ball")
#' @param color.code What the colors of the points signify. Defaults to "pitchtype". Other options: result, hittype, biptype. Must be in quotation marks.
#' @param plot.title The title of the plot. Leave default unless you want a specific custom title.
#' @param save Whether to save the graph. Defaults to FALSE.
#' @param path Where to save the graph. Defaults to the current working directory.
#' @export

sz_graph = function(batter = "all", pitcher = "all", count = "all",
                    startdate = '2016-01-01', enddate = '2016-12-31', year = 0,
                    stand = "R','L", throws = "R','L", size = 3, heatmap = FALSE, 
                    pitchtypes = "all", color.code = "pitchtype", plot.title = "default",
                    save = FALSE, path = getwd()) {
  
  if (!dateformat(startdate)) {
    stop("startdate not valid (must be yyyy-mm-dd)")
  } else if (!dateformat(enddate)) {
    stop("enddate not valid (must be yyyy-mm-dd)")
  } else if (startdate > enddate) {
    stop("Start date is after the end date")
  } else if (!stand %in% c("R','L","R","L")) {
    stop('Enter a valid handedness for stand ("R" or "S")\nLeave default for both')
  } else if (!is.logical(save)) {
    stop("Input a logical value for save (TRUE or FALSE)")
  } else if (is.na(as.numeric(size))) {
    stop("Input a number for size")
  } else if (!is.logical(heatmap)) {
    stop("Input a logical value for save (TRUE or FALSE)")
  } else if (!color.code %in% c("pitchtype","hittype","biptype","result","umpire")) {
    stop('color.code must be one of the following:\n"pitchtype", "hittype", "biptype", "result", "umpire"')
  } else if (heatmap & color.code != "pitchtype") {
    stop("Do not use color.code when creating a heatmap")
  }
  
  if (year != 0) {
    startdate = paste0(year,"-01-01")
    enddate = paste0(year,"-12-31")
  }
  
  if (!"all" %in% pitchtypes) {
    invalid.pitches = c()
    for (i in pitchtypes) {
      if (!i %in% c("Breaking ball", "Changeup", "Cutter", "Four-seam fastball", "Knuckleball", "Splitter", "Two-seam fastball"))
      invalid.pitches[length(invalid.pitches)+1] = i
    }
    if (length(invalid.pitches) > 1) {
      ip = paste0(invalid.pitches,collapse = ", ")
      warning(paste(ip,"are not valid pitch types.\nValid pitch types:\n'Breaking ball', 'Changeup', 'Cutter', 'Four-seam fastball', 'Kunckleball', 'Splitter', 'Two-seam fastball'\nPitches ARE case-sensitive"))
    } else if (length(invalid.pitches == 1)) {
      warning(paste(invalid.pitches[1],"is not a valid pitch type.\nValid pitch types:\n'Breaking ball', 'Changeup', 'Cutter', 'Four-seam fastball', 'Kunckleball', 'Splitter', 'Two-seam fastball'\nPitches ARE case-sensitive"))
    }
  }

  batter.id = NA
  pitcher.id = NA
  
  if (pitcher != "all") {
    if (!(pitcher %in% ids$PlayerId) & pitcher != "all") {
      pitcher.id = filter(ids,Name == pitcher)$PlayerId[1]
    } else if (pitcher != "all") {
      pitcher.id = pitcher
    }
    pitcher.query = paste0(" and p.playerid = ",pitcher.id)
  } else {
    pitcher.query = ""
  }
  
  if (batter != "all") {
    if (!(batter %in% ids$PlayerId) & batter != "all") {
      batter.id = filter(ids,Name == batter)$PlayerId[1]
    } else if (batter != "all") {
      batter.id = batter
    }
    batter.query = paste0(" and b.playerid = ",batter.id)
  } else {
    batter.query = ""
  }
  
  ball.query = ""
  strike.query = ""
  if (count != "all") {
    balls = substring(count,1,1)
    strikes = substring(count,3,3)
    if (balls != "x") {
      ball.query = paste(" and startballs =",balls)
    }
    if (strikes != "x") {
      strike.query = paste(" and startstrikes =",strikes)
    }
  }
  
  if (is.na(batter.id) & batter != "all") {
    stop("Invalid batter name or ID")
  } 
  if (is.na(pitcher.id) & pitcher != "all") {
    stop("Invalid pitcher name or ID")
  }
  
  query.add = ""
  if (color.code == "pitchtype") {
    scale.colors = c(fg_green,fg_orange,fg_blue,fg_red,"purple","yellow","black")
    col = 3
    title.add = "Pitch Types"
  } else if (color.code == "result") {
    scale.colors = c(fg_green,"yellow",fg_blue,"purple","black",fg_red)
    col = 5
    title.add = "Pitch Results"
  } else if (color.code == "hittype") {
    scale.colors = c("lightblue",fg_green,fg_orange,fg_red,"black")
    query.add = " having hittype is not null"
    col = 6
    title.add = "Hit Types"
  } else if (color.code == "biptype") {
    scale.colors = c("black","lightblue",fg_red,fg_green)
    query.add = " having biptype is not null"
    col = 7
    title.add = "Ball-in-Play Types"
  } else if (color.code == "umpire") {
    scale.colors = c("lightblue",fg_red)
    query.add = " having result in ('Ball','Called Strike')"
    col = 8
    title.add = "Called Strike Map"
  }
  if (heatmap) {
    title.add = "Pitch Location Heatmap"
  }
  
  query = paste0("select px, pz, case when pitch_type in ('FF','FA') then 'Four-seam fastball' when pitch_type in ('SI','FT') then 'Two-seam fastball' when pitch_type in ('CU','SL','KC','SC','EP','FO') then 'Breaking ball' when pitch_type = 'CH' then 'Changeup' when pitch_type = 'FC' then 'Cutter' when pitch_type = 'FS' then 'Splitter' when pitch_type = 'KN' then 'Knuckleball' else NULL end as pitch, stand, case when des2 like 'foul%' and des2 != 'foul tip' then 'Foul' when des2 like 'in play%' then 'In Play' when des2 like 'swinging%' or des2 like 'foul tip' or des2 like 'missed%' then 'Swinging Strike' when des2 like '%ball%' then 'Ball' when des2 like 'called%' then 'Called Strike' when des2 like 'hit by%' then 'Hit by Pitch' else null end as Result, case when des2 like 'in play%' then case when event1 not in ('single','double','triple','home run') then 'Out' else event1 end else NULL end as HitType, case when finalpitch = 1 and (des1 like '%grounds%' or des1 like '%ground ball%') then 'Ground Ball' when finalpitch = 1 and (des1 like '%flies%' or des1 like '%fly ball%' or des1 like '%sacrifice fly%' or des1 like '%grand slam%') then 'Fly Ball' when finalpitch = 1 and (des1 like '%lines%' or des1 like '%line drive%') then 'Line Drive' when finalpitch = 1 and (des1 like '%pops%' or des1 like '%pop out%') then 'Popup' else NULL end as BIPType, case when des2 like 'ball%' then 'Ball' else 'Called Strike' end as CS from gd_pitch g join playerid_lookup b on b.mlbamid = g.batter join playerid_lookup p on p.mlbamid = g.pitcher where gamedate between '",
                startdate, "' and '", enddate, 
                "' and pitch_type not in ('AB','PO','IN','UN') and pitch_type is not null",
                batter.query,pitcher.query,ball.query,strike.query,
                " and stand in ('", stand,"')",
                " and p_throws in ('", throws,"')",
                query.add)
  pitches = FGQuery(query)
  
  if (nrow(pitches) == 0) {
    stop("No pitches match given parameters")
  }
  
  stand_ = mean(pitches$stand == "R")
  if (stand_ == 1) {
    batside = "R"
  } else if (stand_ == 0) {
    batside = "L"
  } else {
    batside = "S"
  }

  if (!is.na(batter.id)) {
    batter.name = filter(ids,PlayerId == batter.id)$Name
    heights = FGQuery('select PlayerId, Height from player_info')
    height = filter(heights,PlayerId == batter.id)$Height
    sz_t_r = height/12*.136 + 2.6
    sz_t_l = height/12*.228 + 2
    sz_b_r = height/12*.136 + .92
    sz_b_l = height/12*.229 + .35
    if (batside == "R") {
      sz_top = sz_t_r
      sz_bot = sz_b_r
    } else if (batside == "L") {
      sz_top = sz_t_l
      sz_bot = sz_b_l
    } else {
      sz_top = mean(sz_t_r, sz_t_l)
      sz_bot = mean(sz_b_r, sz_b_l)
    }
  }
  
  if (!is.na(pitcher.id)) {
    pitcher.name = filter(ids,PlayerId == pitcher.id)$Name
  }
  
  if (is.na(batter.id)) {
    sz_top = sz_top
    sz_bot = sz_bot
  }
  
  if (!"all" %in% pitchtypes) {
    pitches = filter(pitches, pitch %in% pitchtypes)
  }
  
  x = data.frame(px=c(1000,1000,1000,1000,1000,1000,1000), 
                 pz=c(1000,1000,1000,1000,1000,1000,1000),
                 pitch = c("Breaking ball","Four-seam fastball","Changeup","Splitter","Two-seam fastball","Cutter","Knuckleball"),
                 stand = c("X","X","X","X","X","X","X"),
                 Result = c("Swinging Strike","Ball","Called Strike","Foul","In Play","Hit by Pitch","Swinging Strike"),
                 HitType = c("Single","Double","Triple","Home Run","Out","Single","Single"),
                 BIPType = c("Ground Ball","Fly Ball","Line Drive","Popup","Ground Ball","Ground Ball","Ground Ball"),
                 CS = c("Ball","Ball","Ball","Ball","Ball","Ball","Ball"))
  
  pitches = rbind(pitches,x)
  
  pitches$HitType = factor(pitches$HitType, levels = c("Out","Single","Double","Triple","Home Run"))
  
  time = datify(startdate, enddate)
    
  if (batter != "all" & pitcher != "all") {
    title = paste(batter.name, "vs.", pitcher.name)
  } else if (batter != "all" & pitcher == "all") {
    title = batter.name
  } else if (batter == "all" & pitcher != "all") {
    title = pitcher.name
  } else {
    title = "All Batters and Pitchers"
  }
  title = paste(title,title.add)
  title = paste0(title,", ",time)

  if (plot.title != "default") {
    title = plot.title
  }
  
  subt = ""
  if (stand != "R','L") {
    standdesc = ifelse(stand == "R","Righty","Lefty")
    if (is.na(batter.id)) {
      subt = paste0(subt,standdesc," batters only. ")
    } else {
      subt = paste0(subt,"As ",standdesc," only. ")
    }
  }
  if (throws != "R','L") {
    throwsdesc = ifelse(throws == "R","Righty","Lefty")
    subt = paste0(subt,throwsdesc," pitchers only. ")
  }
  if (count != "all") {
    if (substring(count,1,1) == "x") {
      subt = paste0(subt,strikes,"-strike counts only. ")
    } else if (substring(count,3,3) == "x") {
      subt = paste0(subt,balls,"-ball counts only. ")
    } else {
      subt = paste0(subt,count," counts only. ")
    }
  }
  if (!"all" %in% pitchtypes) {
    subt = paste0(subt,substring(pitchtypes[1],1,1),
                 substring(tolower(paste0(paste(pitchtypes,collapse=", ")," only.")),2))
  }
  
  capt = "Catcher's perspective. Source: PITCHf/x"
  
  if (subt == "") {
    plot.title = ggtitle(title)
  } else {
    plot.title = ggtitle(title, subtitle = subt)
  }
  
  if (!heatmap) {
    g = ggplot(pitches, aes(x=px, y=pz, color = pitches[,col])) +
      geom_point(alpha = .5, size = size) +
      geom_segment(x=sz_left, xend=sz_right, y=sz_bot, yend = sz_bot, color = "black", size = 1, lineend = "round") +
      geom_segment(x=sz_left, xend=sz_right, y=sz_top, yend = sz_top, color = "black", size = 1, lineend = "round") +
      geom_segment(x=sz_left, xend=sz_left, y=sz_top, yend = sz_bot, color = "black", size = 1, lineend = "round") +
      geom_segment(x=sz_right, xend=sz_right, y=sz_top, yend = sz_bot, color = "black", size = 1, lineend = "round") +
      fgt +
      coord_cartesian(xlim=c(-3,3),ylim=c(0,6)) +
      geom_segment(x=-5,xend=5,y=0,yend=0,size=.75,color="black") +
      scale_color_manual(values = scale.colors, name = "") +
      labs(x="",y="",caption = capt) +
      plot.title +
      theme(axis.text=element_text(size=0), 
            panel.grid.major = element_line(size=0),
            axis.ticks = element_line(size=0),
            panel.background = element_rect(color="white")) +
      guides(colour = guide_legend(override.aes = list(size=4)))
  } else {
    if (batter != "all") {
      scale.name = "Pitches Seen"
    } else {
      scale.name = "Pitches Thrown"
    }
    g = ggplot(pitches, aes(x=px,y=pz)) +
      geom_bin2d(binwidth = c(.2,.2)) +
      geom_segment(x=sz_left, xend=sz_right, y=sz_bot, yend = sz_bot, color = "black", size = 1, lineend = "round") +
      geom_segment(x=sz_left, xend=sz_right, y=sz_top, yend = sz_top, color = "black", size = 1, lineend = "round") +
      geom_segment(x=sz_left, xend=sz_left, y=sz_top, yend = sz_bot, color = "black", size = 1, lineend = "round") +
      geom_segment(x=sz_right, xend=sz_right, y=sz_top, yend = sz_bot, color = "black", size = 1, lineend = "round") +
      fgt +
      coord_cartesian(xlim=c(-3,3),ylim=c(0,5)) +
      geom_segment(x=-5,xend=5,y=0,yend=0,size=.75,color="black") +
      scale_fill_gradient(low="white",high=fg_green,name=scale.name) +
      labs(x="",y="", caption = capt) +
      plot.title +
      theme(axis.text=element_text(size=0), 
            panel.grid.major = element_line(size=0), 
            axis.ticks = element_line(size=0),
            panel.background = element_rect(color="white")) +
      guides(color = guide_legend(nrow = 1)) +
      guides(colour = guide_legend(override.aes = list(size=4)))
  }
  
  fname = paste0(gsub("\\.","",gsub(" ","_",gsub(", ","_",title))),".png")

  if (save) {
    ggsave(filename = fname,
           path = path,
           height = 7,
           width = 8)
  }
  
  return(g)
}