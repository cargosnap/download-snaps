# Backup images script for CargoSnap API
# By Marcel Merkx - 18-10-2019

# retrieve command line parameters
param(
    [Parameter(Mandatory=$true)][string]$token, 
    [string]$destination_path = (Split-Path -parent $PSCommandPath),
    [int]$days_back = 7
)

$my_path = Split-Path -parent $PSCommandPath
$log_file = "$my_path\backup_$(get-date -format `"yyyyMMdd`").log"
$api_route = "https://platform.cargosnap.com/api/v2/files"

Function Main() {
    # this code has the "problem" that is calls the API 1 time to get the page count and then makes the same
    # first call to get the responses. there will be a smarter way to handle that, but I will leave that to the smarter programmers after me :)

    $start_date = (get-date).AddDays(-$days_back).ToString("yyyy-MM-dd") 
    $query_string = "format=json&token=$token&limit=10&include[]=uploads&startdate=$start_date"

    $request = $api_route + "?" + $query_string
    $response = Invoke-RestMethod -uri $request -Method Get -ContentType "application/json"

    $resultpages = $response.last_page
    
    Do {
        [int]$incpages += 1
        $url = $api_route + "?" + $query_string + "&page=$incpages"
        $getresults = Invoke-RestMethod -uri $url -Method Get -ContentType "application/json"
        $result_array += $getresults.data
        $resultpages -= 1
    } while ($resultpages -gt 0)

    $files_array = $result_array | Select-Object id, scan_code, uploads

    $WebClient = New-Object System.Net.WebClient

    foreach ($file in $files_array) {

        log ("Handling file: " + $file.scan_code) green

        $file_path = $destination_path + "\" + (Remove-InvalidFileNameChars($file.scan_code))
        If(!(test-path $file_path)) {
            New-Item -ItemType Directory -Force -Path $file_path
        }

        $images_array = $file | 
                        Select-Object -expand uploads |
                        Select-Object image_url, scan_date_time

        foreach ($image in $images_array) {

            $image_path = $file_path + "\" + (Remove-InvalidFileNameChars($image.scan_date_time))  +".jpg" 

            if ( -not (Test-Path $image_path) ) {
                try {
                    $WebClient.DownloadFile( $image.image_url, $image_path ) 
                    log ("success: downloaded: " + $image_path) green
                } catch {
                    log ("whoops!!! could not download " + $image.image_url) red
                }
            } else {
                log "skipping $image_path, already downloaded" white
            }
        }
    }
}

Function log($log_string, $color) {

   if ($null -eq $color) {$color = "white"}
   Write-Host $log_string -ForegroundColor $color
   $log_string | out-file -Filepath $log_file -append
}

Function Remove-InvalidFileNameChars ($name) {

    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
    return ($name -replace $re)
  }


Main    # this is where we call the main function