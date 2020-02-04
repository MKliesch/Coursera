# SBB Connections from Bern and Zurich ###


library(shiny)
library(leaflet)
library(dplyr)

# Load data
all <- read.csv(file = "data/dfComplete.csv", header = T)


# Define server logic required to draw a histogram
shinyServer(function(input, output) {

    output$distPlot <- renderLeaflet({
        
        # get variables from input
        popsize_min = input$popsize[1]
        popsize_max = input$popsize[2]
        nConn_min = input$nConn[1]
        nConn_max = input$nConn[2]
        duration_min = input$duration[1]
        duration_max = input$duration[2]
        city = input$city
        monday = input$monday
        tuesday = input$tuesday
        wednesday = input$wednesday
        thursday = input$thursday
        friday = input$friday
        saturday = input$saturday
        sunday = input$sunday
        
        
        # choose only columns of the days that were selected
        idxDays <- c(monday,tuesday,wednesday,thursday,friday,saturday,sunday)
        dayColsZh <- c("toZhPerHMon", "toZhPerHTue", "toZhPerHWed", "toZhPerHThu", "toZhPerHFri", "toZhPerHSat", "toZhPerHSun")
        dayColsBern <- c("toBernPerHMon", "toBernPerHTue", "toBernPerHWed", "toBernPerHThu", "toBernPerHFri", "toBernPerHSat", "toBernPerHSun")
        dayColsBoth <- c("toBothPerHMon", "toBothPerHTue", "toBothPerHWed", "toBothPerHThu", "toBothPerHFri", "toBothPerHSat", "toBothPerHSun")
        
        # make a preselection of dataset
        if (city %in% c("Zürich", "Bern")) { # If both are selected, the dataset has to be treated differently
            if(city == "Zürich") {
                df <- all %>%
                    filter(    population < popsize_max & # limit to towns with certain population size
                                   population > popsize_min &
                                   avDurToZh > duration_min & # limit to rows with certain duration to Zurich
                                   avDurToZh < duration_max &
                                   name != "Zurich") %>%
                    mutate(inverseDuration = round((0 - avDurToZh + 474),2), # invert duration, so that small is big (for circle weight)
                           avDurToZh = round(avDurToZh,2), # round duration to 2 decimals
                           population = round(population)) #r round population to 2 decimals
                
                daysSelected <- dayColsZh[which(idxDays == T)] # say which day columns to include
                tmp <- df[which(names(df) %in% daysSelected)]
                df$ThisNPerHour <- round(rowMeans(tmp),2) # average number of connections per hour over the days selected
                
                df <- df %>%
                    filter(ThisNPerHour > nConn_min & # filter places with a certain number of connections per hour
                               ThisNPerHour < nConn_max) %>%
                    mutate(avDur = avDurToZh) # make a general duration column to plot independently of Zurich/Bern
                
            } else { # i.e. if city is Bern
                df <- all %>%
                    filter(    population < popsize_max & # limit to towns with certain population size
                                   population > popsize_min &
                                   avDurToBern > duration_min & # limit to places with certain duration to Bern
                                   avDurToBern < duration_max & 
                                   name != "Bern") %>% # remove Bern itself
                    mutate(inverseDuration = round((0 - avDurToBern + 142),2), # invert duration so that small is big
                           avDurToBern = round(avDurToBern,2), # round duration
                           population = round(population)) # round population
                
                daysSelected <- dayColsBern[which(idxDays == T)] # say which day columns to include
                tmp <- df[which(names(df) %in% daysSelected)]
                df$ThisNPerHour <- round(rowMeans(tmp),2) # average connections per hour over days selected
                
                df <- df %>%
                    filter(ThisNPerHour > nConn_min & # limit to connections with a certain frequency per hour
                               ThisNPerHour < nConn_max) %>%
                    mutate(avDur = avDurToBern) # make a general duration column for plotting independently of Bern/Zürich
            }
            
            
            # Plot with leaflet
            if(length(df$name) > 0) { # if there are any place to plot
                pal = colorFactor(palette = c("blue", "red"), domain = df$avDur)
                
                df %>%
                    leaflet() %>%
                    addTiles() %>%
                    addCircles(lng = df$lng, lat = df$lat,
                               radius = 10, weight = 20,
                               color = ~ pal(avDur),
                               popup = paste(df$name, paste(". Size:", df$population), paste(". Trains to", city, "per h:",
                                                                                             df$ThisNPerHour), 
                                             paste(". Av. commute time:", df$avDur, " min."))) %>%
                    addLegend(position = "bottomright", 
                              color = c("red", "blue"),
                              labels = c("Long", "Short"),
                              title = "Average Duration" )
                
            } else { # if there are no places to plot
                m <- leaflet() %>%
                    addTiles() %>%
                    setView(lat = 46.90272, lng = 8.625348, zoom = 7) # set default zoom
            }
            
        } else { # i.e. if "Zürich/Bern" was selected
            
            
            df <- all %>%
                mutate(avDur = rowMeans(data.frame(avDurToBern, avDurToZh)),
                       toBothPerHMon = rowMeans(data.frame(toZhPerHMon, toBernPerHMon)),
                       toBothPerHTue = rowMeans(data.frame(toZhPerHTue, toBernPerHTue)),
                       toBothPerHWed = rowMeans(data.frame(toZhPerHWed, toBernPerHWed)),
                       toBothPerHThu = rowMeans(data.frame(toZhPerHThu, toBernPerHThu)),
                       toBothPerHFri = rowMeans(data.frame(toZhPerHFri, toBernPerHFri)),
                       toBothPerHSat = rowMeans(data.frame(toZhPerHSat, toBernPerHSat)),
                       toBothPerHSun = rowMeans(data.frame(toZhPerHSun, toBernPerHSun))) %>%
                filter(population < popsize_max & # limit to towns with certain population size
                               population > popsize_min &
                               avDur > duration_min & # limit to places with certain duration to Bern/Zurich
                               avDur< duration_max & 
                               name %in% c("Bern", "Zürich") == F) %>% # remove Bern and Zurich itself
                mutate(inverseDuration = round((0 - avDur + 179),2), # invert duration so that small is big
                       avDur = round(avDur,2), # round duration
                       population = round(population)) # round population
            
            daysSelected <- dayColsBoth[which(idxDays == T)] # say which day columns to include
            tmp <- df[which(names(df) %in% daysSelected)]
            df$ThisNPerHour <- round(rowMeans(tmp),2) # average connections per hour over days selected
            
            df <- df %>%
                filter(ThisNPerHour > nConn_min & # limit to connections with a certain frequency per hour
                           ThisNPerHour < nConn_max)

        
        # Plot with leaflet
        if(length(df$name) > 0) { # if there are any place to plot
            pal = colorFactor(palette = c("blue", "red"), domain = df$avDur)
            
            df %>%
                leaflet() %>%
                addTiles() %>%
                addCircles(lng = df$lng, lat = df$lat,
                           radius = 10, weight = 20,
                           color = ~ pal(avDur),
                           popup = paste(sep = "<br/>", 
                                         df$name, 
                                         paste("Size: ", df$population, sep = ""), 
                                         paste("Trains to", city, "per h: ",
                                               df$ThisNPerHour, sep = ""), 
                                         paste("Av. commute time to Zurich: ", round(df$avDurToZh,2), " min.", sep = ""),
                                         paste("Av. commute time to Bern: ", round(df$avDurToBern,2), " min.", sep = ""))) %>%
                addLegend(position = "bottomright", 
                          color = c("red", "blue"),
                          labels = c("Long", "Short"),
                          title = "Average Duration" )
            
        } else { # if there are no places to plot
            m <- leaflet() %>%
                addTiles() %>%
                setView(lat = 46.90272, lng = 8.625348, zoom = 7) # set default zoom
        }
            
        }
        
    })
})
