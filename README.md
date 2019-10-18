# Snap download-api

Use your CargoSnap API key to download all images in your files. For backup or export.

Based on the input parameters, this utility will create folders for each of your files and place the "snaps" that have been generated in that file into that folder. Mimicking the way it used to work whn you where using a digital camera and a USB cable, remember? :-p

## Prerequisites
You need a CargoSnap API token:
* Get a license
* Create token
* Keep this token super safe!

System with PowerShell installed (default for Windows 10, others see https://github.com/powershell/powershell )

## Installation
Download the file "download-snaps.ps1" to your machine

## Usage
Open a PS prompt (Windows: Start -> Windows PowerShell -> Windows PowerShell) in the folder you used to store the download-snaps.ps1 file, and run the ./download-snaps as follows:

``` PowerShell
./download-snaps -token [your-token-from-cargosnap] -destination_path ['c:\data\cargosnap\snap-backups'] -days_back 7
```
Replace the variables in the square brackets with your own values. As you can see, there are 3 command line parameters to use:

* -token -> Obtain from your CargoSnap "API-token" screen in "Global Settings" (note: this is a required parameter)
* -destination_path -> the path on your server where the images need to be stored
* -days_back -> contains the number of days in history to download (counted from "today")

So, finally, your call may look like this:
```
c:\cargosnap\download-snaps.ps1 -token sfdgWegwrfQef325f43re4rf2rffsdad -days_back 7 -destination_path d:\data\cargosnap
```    

## Scheduling automatic runs (Windows 10)

To schedule a weekly job (e.g. each Sunday AM):

* open Task Scheduler (In the search box, type Task Scheduler)
* Actions -> Create Task
* Provide a name for the task (e.g. "CargoSnap weekly Snap download")
* Select "Run whether users is logged on or not"
* Triggers -> "New..." -> Settings "Weekly" -> Sunday 8am -> Conform "OK"
* Actions -> "New..." -> 
    * Program/script -> ```powershell```
    * Add arguments (optional) -> ```-command &{[absolut-path-to-script]\download-snaps.ps1 -token [your-token-from-cargosnap] -days_back 7 -destination_path [folder-to-store-the-snaps]}```
* Leave the rest default

It has now been scheduled!
