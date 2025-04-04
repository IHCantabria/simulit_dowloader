INSTRUCTION MANUAL FOR CLIMATE DATA DOWNLOAD FUNCTION
=====================================================
The data to be downloaded here is available thorugh a user interface here: https://ocle.ihcantabria.com/

Funcionality:
-----------------------
This tool helps you download climate data (like ocean temperatures, wind speeds, etc.) from a scientific database. You can get:
- Past measurements ("Historical" data)
- Future projections ("Projected" data)
- In different formats (maps, spreadsheets, etc.)

Basic Requirements:
------------------
- R software installed (free from https://www.r-project.org/)
- These R packages installed: ncdf4, raster, lubridate
- Internet connection

Step-by-Step Guide:
-------------------

1. SETTING UP:
Before using, copy the entire download_data() function code into R. Or Source() the function file.

2. BASIC STRUCTURE:
Always use this format:
download_data(
  period = "[Historical/Projected]",
  variable = "[ex: SST, Wind]",
  parameter = "[ex: Mean, Max]",
  temporal_resolution = "[ex: yearly, summer]",
  save_path = "[folder to save]",
  year_or_season = [year number],
  scenario = "[only for Projected]",
  output_format = "[nc, csv, etc.]",
  return_object = TRUE/FALSE
)

3. PARAMETER DETAILS:

A) period (required):
- "Historical": Real measurements from the past
- "Projected": Future climate predictions

B) variable (required):
Available options depend on period:

Historical options:
- pH
- Wind 
- TidalRange
- Salinity 
- SST (sea surface temperature)
- PAR (light availability)
- Nitrate 
- MHW (marine heat waves)
- MCS (marine cold spells)
- Hs (wave heights)
- Currents (ocean currents)
- AirTemperature

Projected options (future):
- pH, Wind, Salinity, SST, SLR (sea level rise)
- Nitrates, Hs, AirTemperature

C) parameter (required):
Choose how to summarize the data:
- Max (maximum value)
- Mean (average value)
- Min (minimum value)
- Percentile10/50/90 (statistical measures)
Note: MHW/MCS only accept Max/Min/Mean

D) temporal_resolution (required):
Time period covered:
- "yearly" (full year)
- "winter" (De-Feb)
- "spring" (Mar-May)
- "summer" (Jun-Aug)
- "autumn" (Sep-Nov)
- "all" (all available times)

E) save_path (required):
Where to save files. Examples:
- "C:/Users/YourName/ClimateData"
- "/home/user/Documents/Data"
Note: Will create folder if it doesn't exist

F) year_or_season (required):
For Historical:
- 2000-2020 (yearly data)
- Ignored for seasonal data

For Projected:
- 2050 or 2100 only

G) scenario (Projected only):
Future climate scenario:
- "SSP245" (moderate emissions)
- "SSP585" (high emissions)

H) output_format (optional):
File format to save:
- "nc" (scientific map format) - DEFAULT
- "ascii" (text map)
- "csv" (spreadsheet)
- "rdata" (R-specific format)

I) return_object (optional):
- TRUE: Shows data in R after saving - DEFAULT
- FALSE: Just saves files

4. SPECIAL CASES:

For MHW/MCS (marine heat/cold waves):
- Only yearly data available
- Only Max/Min/Mean parameters work
- Will warn if wrong settings used

For SLR (sea level rise):
- No parameter needed
- Only available for Projected period

5. EXAMPLE USES:

Example 1: Get average summer sea temperatures for 2010
download_data(
  period = "Historical",
  variable = "SST",
  parameter = "Mean",
  temporal_resolution = "summer",
  year_or_season = 2010,
  save_path = "C:/ClimateData",
  output_format = "csv"
)

Example 2: Get future high-emission wind speeds for 2100
download_data(
  period = "Projected",
  variable = "Wind",
  parameter = "Max",
  temporal_resolution = "yearly",
  year_or_season = 2100,
  scenario = "SSP585",
  save_path = "/home/user/Downloads",
  output_format = "nc"
)

6. TROUBLESHOOTING:

Common errors:
- "Variable not found": Check spelling and period compatibility
- "Year not available": Historical data only goes to 2020
- "Invalid parameter": Some variables have restrictions
- Folder permissions: Make sure you can write to save_path

7. OUTPUT EXPLANATION:

Depending on format:
- nc/ascii: Map files (use in GIS software)
- csv: Spreadsheet with columns (lon, lat, value)
- rdata: For use in R only

The function will tell you where files were saved.
