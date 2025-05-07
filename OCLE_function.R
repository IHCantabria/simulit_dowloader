

# OCLE download
# Function to download environmental information from OCLE database (https://ocle.ihcantabria.com/)

# Predefined available variables for each period
available_variables_historical <- c("pH", "Wind", "TidalRange", "ShearStress", "Salinity", "SST", "PAR", "Nitrate", "MHW", "MCS", "Hs", "Currents", "BottomOrbitalSpeed", "AttenuationCoefficient", "AirTemperature")
available_variables_projected <- c("pH", "Wind", "Salinity", "SST", "SLR", "Nitrates", "Hs", "AirTemperature")

# Function to get available variables based on the selected period
get_available_variables <- function(period) {
  if (period == "Historical") {
    return(available_variables_historical)
  } else if (period == "Projected") {
    return(available_variables_projected)
  } else {
    stop("Invalid period")
  }
}

download_data <- function(period, variable, parameter,
                         temporal_resolution, save_path,
                         year_or_season = NULL,
                         scenario = NULL,
                         lat_max = NULL,
                         lat_min = NULL,
                         lon_min = NULL,
                         lon_max = NULL,
                         output_format = "nc",  # Options: "ascii", "nc", "csv", "rdata"
                         return_object = TRUE
                         ) {
  
  # Load required packages
  if (!requireNamespace("ncdf4", quietly = TRUE)) install.packages("ncdf4")
  if (!requireNamespace("httr", quietly = TRUE)) install.packages("httr")
  if (!requireNamespace("raster", quietly = TRUE)) install.packages("raster")
  library(ncdf4)
  library(httr)
  library(raster)
  
  # Ensure save path exists
  if (!dir.exists(save_path)) dir.create(save_path, recursive = TRUE)
  
  #_________________________
  # Validate output format
  #_________________________
  if (!output_format %in% c("ascii", "nc", "csv", "rdata")) {
   stop("Invalid output_format. Choose 'ascii', 'nc', 'csv', or 'rdata'")
  }
 
  # Construct URL
  base_url <- "https://ihthredds.ihcantabria.com/thredds/fileServer/SIMULIT"
  
  if (period == "Historical") {
    dataset_url <- paste0(base_url, "/",
                          period, "/",
                          variable, "/",
                          variable, "_",
                          ifelse(temporal_resolution == "range", "yearly",
                                 ifelse(temporal_resolution == "full", "all", temporal_resolution)), 
                          ".nc")
  } else if (period == "Projected") {
    dataset_url <- paste0(base_url, "/",
                          period, "/",
                          variable, "/",
                          scenario, "/",#                          year_or_season,
                          variable,# "_",
                          ".nc")
  } else {
    stop("Invalid period")
  }
  
  #_________________________
  # Download file
  #_________________________
  temp_file <- tempfile(fileext = ".nc")
  response <- GET(
  dataset_url,
  write_disk(temp_file, overwrite = TRUE),
  config(followlocation = TRUE),  # Follow redirects (common in THREDDS)
  timeout(3000000),                   # Increase timeout (default: 60s)
  progress()
  )
  if (http_error(response)) stop("Failed to download file")
  
  # Open file
  nc <- nc_open(temp_file)
  on.exit({
    nc_close(nc)
    unlink(temp_file)
  })
  
  #_________________________
  # Get parameter name 
  #_________________________
  
  if(variable =="MHW"|variable =="MCS"){
    parameter <- variable
  full_param_name <- variable
   
  }else{
  full_param_name <- paste0(variable, "_", parameter)
      if (!full_param_name %in% names(nc$var)) {
    stop(paste("Parameter not found. Available parameters:",
               paste(names(nc$var), collapse = ", ")))
  }
  }
  

  
  #______________________________________________________________
  # Handle time dimension differently for seasonal vs yearly data
  #_________________________________________________________
  if (temporal_resolution == "yearly"|temporal_resolution == "range") {

    time_vals <- ncvar_get(nc, "time")
    time_units <- ncatt_get(nc, "time", "units")$value

    if (grepl("days since", time_units)) {
      time_dates <- as.Date(sub(".*since ", "", time_units)) + time_vals
    } else if (grepl("seconds since", time_units)) {
      time_dates <- as.POSIXct(sub(".*since ", "", time_units), tz="UTC") + as.difftime(time_vals, units="secs")
    } else {
      stop("Unrecognized time format")
    }

    time_years <- as.integer(format(time_dates, "%Y"))
    print(paste("Available years:", paste(unique(time_years), collapse=", ")))

    #______________________________
    # Selecting the required years 
    #______________________________
    if (length(year_or_season)== 1) {
      year_index <- which(time_years == as.numeric(year_or_season))
      if (length(year_index) == 0) stop("Requested year not available")
      data <- ncvar_get(nc, full_param_name,
                        start = c(1, 1, year_index),
                        count = c(-1, -1, 1))
    }else if(length(year_or_season) >1){
     # For multiple years
      year_indices <- which(time_years %in% year_or_season)
      
      # Get all the data for those years
      data <- ncvar_get(nc, full_param_name, 
                       start = c(1, 1, min(year_indices)), 
                       count = c(-1, -1, length(year_indices)))
            
    } else {
      data <- ncvar_get(nc, full_param_name)
    }
    
  }else {
    # Seasonal data - no time dimension to process
    data <- ncvar_get(nc, full_param_name)
  }
   

  #______________________________________________________
  # Create output file
  #______________________________________________________
  lon <- ncvar_get(nc, "lon")
  lat <- ncvar_get(nc, "lat")
  
  #________________________
  # Filtering by dimensions 
  #________________________
  if (!is.null(lat_max) || !is.null(lat_min) || !is.null(lon_min) || !is.null(lon_max)) {
    
    # Set defaults if NULL (entire range)
    if (is.null(lat_max)) lat_max <- max(lat)
    if (is.null(lat_min)) lat_min <- min(lat)
    if (is.null(lon_max)) lon_max <- max(lon)
    if (is.null(lon_min)) lon_min <- min(lon)
    
    # Find indices for subsetting
    lat_indices <- which(lat >= lat_min & lat <= lat_max)
    lon_indices <- which(lon >= lon_min & lon <= lon_max)
    lon <- lon[lon_indices]
    lat <- lat[lat_indices]
    
  if(period == "Projected"){
    data <- data[lon_indices, lat_indices,]  
  }else{
        # Because year adds another dimension
    if (length(year_or_season)== 1) {
      data <- data[lon_indices, lat_indices]  
    }else if(length(year_or_season) >1){
      data <- data[lon_indices, lat_indices,]  
    }
    
  }

    
  }
  
   #______________________________________________
    # Creating the raster with the correct rotation 
    #_______________________________________________
    if (period == "Projected") { #Create raster with 90-degree counter-clockwise rotation
      rotated_matrix <- t(data)[ncol(data):1,]  # Rotate 90 degrees left
      r <- raster(rotated_matrix,
                  xmn = min(lon), xmx = max(lon),
                  ymn = min(lat), ymx = max(lat),
                  crs = CRS("+proj=longlat +datum=WGS84"))
    }
    if (period == "Historical" & temporal_resolution != "yearly") {
      rotated_matrix <- t(data)[,nrow(data):1]  # Simple right rotation
      r <- raster(rotated_matrix,
                  xmn = min(lon), xmx = max(lon),
                  ymn = min(lat), ymx = max(lat),
                  crs = CRS("+proj=longlat +datum=WGS84"))
      r <-  flip(r, direction = 'x')
    }
    
    if (period == "Historical" & temporal_resolution == "yearly") {
      # Rotate the matrix and create the raster
      rotated_matrix <- t(data)[ncol(data):1,]  # Rotate 90 degrees left
      r <- raster(rotated_matrix,
                  xmn = min(lon), xmx = max(lon),
                  ymn = min(lat), ymx = max(lat),
                  crs = CRS("+proj=longlat +datum=WGS84"))
    }
    
    # Create filename
    fname_base <- paste0(
      variable, 
      if (!variable %in% c("MHW", "MCS", "SLR")) paste0("_", parameter) else "",
      "_",
      if (period == "Historical" && temporal_resolution == "yearly") "yearly_" else "",
      year_or_season,
      if (period == "Projected") paste0("_", scenario) else ""
    )
  
  #_________________________________________
  # Output handling based on user selection
  #_________________________________________
  if (output_format == "ascii") {
    raster::writeRaster(r, file.path(save_path, paste0(fname_base, ".asc")), format = "ascii", overwrite = TRUE)
  } else if (output_format == "nc") {
    raster::writeRaster(r, file.path(save_path, paste0(fname_base, ".nc")), format = "CDF", overwrite = TRUE)
  } else {
    df <- as.data.frame(r, xy = TRUE)
    colnames(df) <- c("lon", "lat", "value")
    
    if (output_format == "csv") {
      write.csv(df, file.path(save_path, paste0(fname_base, ".csv")), row.names = FALSE)
    } else if (output_format == "rdata") {
      save(df, file = file.path(save_path, paste0(fname_base, ".RData")))
    }
  }
  
  if (return_object) {
    if (output_format %in% c("ascii", "nc")) return(r) else return(df)
  } else {
    return(invisible(NULL))
  }
}
# # # Define parameters
# period <- "Historical"  # Options: "Historical" or "Projected"
# variable <- "MHW"  # Change according to the desired variable
# parameter <- "Mean"  # Options: Max, Mean, Min, Std,Percentile10, Percentile50, Percentile90
# temporal_resolution <- "yearly"  # Options: range, "yearly", "winter", "summer", "spring", "autumn", "all"
# year_or_season <- 2015 # Selecth the year if "yearly"
# scenario <- NULL  # "SSP245" or "SSP585" if "Projected"
# save_path <- getwd() # Path where the file will be saved
# 
# # Get the list of available variables
# available_variables <- get_available_variables(dataset_period)
# print("Available variables:")
# print(available_variables)
# 
# 
# # Call the function
# download_data(period,
#               variable,
#               parameter,
#               temporal_resolution,
#               save_path,
#               year_or_season,
#               scenario,
#               output_format = "nc" )
