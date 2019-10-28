# Backup images script for CargoSnap API
# By Marcel Merkx - 18-10-2019

param(
    [Parameter(Mandatory=$true)][string]$token, 
    [string]$destination_path = (Split-Path -parent $PSCommandPath),
    [string]$logging_path = (Split-Path -parent $PSCommandPath),
    [int]$days_back = 7
)

$log_file = "$logging_path\backup_$(get-date -format `"yyyyMMdd`").log"
$api_route = "https://platform.cargosnap.com/api/v2/files"

Function Main() {
    # this code has the "problem" that is calls the API 1 time to get the page count and then makes the same first call to
    # get the responses. there will be a smarter way to handle that, but I will leave that to the smarter programmers after me :)

    log ( "Script initialised") info
    $start_date = (get-date).AddDays(-$days_back).ToString("yyyy-MM-dd") 
    $query_string = "format=json&token=$token&limit=200&include[]=uploads&updated_start=$start_date"

    $request = $api_route + "?" + $query_string
    $response = API-Call $request

    $resultpages = $response.last_page
    log ("nr of pages:" + $resultpages) info
    
    Do {
        [int]$incpages += 1
        $url = $api_route + "?" + $query_string + "&page=$incpages"
        $getresults = API-Call $request
        $result_array += $getresults.data
        log ("This page file refs: " + ($getresults.data | Select-Object -expand scan_code)) info
        $resultpages -= 1
    } while ($resultpages -gt 0)

    $files_array = $result_array | Select-Object id, scan_code, uploads
    log ("All files to handle: " + $files_array.id) info                 # TODO remove

    $WebClient = New-Object System.Net.WebClient
    log ("Webclient initialised")  info                                 # TODO remove

    foreach ($file in $files_array) {

        log ("Handling file: " + $file.scan_code) info

        $file_path = $destination_path + "\" + (Remove-InvalidFileNameChars($file.scan_code))
        If(!(test-path $file_path)) {
            New-Item -ItemType Directory -Force -Path $file_path
        }

        $images_array = $file | 
                        Select-Object -expand uploads |
                        Select-Object image_url, scan_date_time

        log ("Contains images: " + $images_array.image_url) info   # TODO remove this one post-troubleshoot

        foreach ($image in $images_array) {

            $image_path = $file_path + "\" + (Remove-InvalidFileNameChars($image.scan_date_time))  +".jpg" 

            if ( -not (Test-Path $image_path) ) {
                try {
                    log ("Downloading: " + $image_path) info
                    $WebClient.DownloadFile( $image.image_url, $image_path ) 
                } catch {
                    log ("Whoops!!! could not download " + $image.image_url) error
                }
            } else {
                log "Skipping $image_path, already downloaded" info
            }
        }
    }
    log "download of images complete" info
}

Function API-Call($url) {
    log ("API call: " + $url) info
    try {
        $response = Invoke-RestMethod -uri $url -Method Get -ContentType "application/json"
    } catch {
        log("API call failed: " + $_.Exception.Message) error
        exit
    }
    log ("API response= " + $response) info
    return ($response)
}

Function log($log_string, $level) {

    $log_string = ("[{0:HH:mm:ss}]: " -f (Get-Date)) + $log_string

    if ($null -eq $level) {$level = "info"}

    $color = switch($level) {
        info      { "white" }
        success   { "green" }
        error     { "red"   }
        default   { "white" }
    }

    if (($level -eq "error") -or ($VerbosePreference -ne 'SilentlyContinue')) {
        Write-Host $log_string -ForegroundColor $color
        $log_string | out-file -Filepath $log_file -append
    }
}


Function Remove-InvalidFileNameChars ($name) {

    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
    return ($name -replace $re)
  }

Main