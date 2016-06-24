﻿#Requires -Version 3
function Get-RubrikTask
{
    <#  
            .SYNOPSIS
            Connects to Rubrik to retrieve either daily or weekly task results
            .DESCRIPTION
            The Get-RubrikTask cmdlet is used to retrieve all of the tasks that have been run by a Rubrik cluster. Use either 'daily' or 'weekly' for ReportType to define the reporting scope.
            .NOTES
            Written by Chris Wahl for community usage
            Twitter: @ChrisWahl
            GitHub: chriswahl
            .LINK
            https://github.com/rubrikinc/PowerShell-Module
            .EXAMPLE
            Get-RubrikTask -ReportType daily -ToCSV
            This will gather all of the daily tasks from Rubrik and store them into a CSV file in the user's MyDocuments folder
            .EXAMPLE
            Get-RubrikTask -ReportType weekly
            This will gather all of the daily tasks from Rubrik and display summary information on the console screen
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Report Type (daily or weekly)')]
        [ValidateNotNullorEmpty()]
        [ValidateSet("daily", "weekly")]
        [String]$ReportType,
        [Parameter(Mandatory = $false,Position = 1,HelpMessage = 'Export the results to a CSV file')]
        [ValidateNotNullorEmpty()]
        [Switch]$ToCSV,
        [Parameter(Mandatory = $false,Position = 2,HelpMessage = 'Rubrik FQDN or IP address')]
        [ValidateNotNullorEmpty()]
        [String]$Server = $global:RubrikConnection.server
    )

    Process {

        TestRubrikConnection

        Write-Verbose -Message 'Build the URI'
        $uri = 'https://'+$Server+'/report/backupJobs/detail'

        Write-Verbose -Message 'Build the body'
        $body = @{
            reportType = $ReportType.ToLower()
        }

        Write-Verbose -Message 'Submit the request'
        try 
        {
            $r = Invoke-WebRequest -Uri $uri -Headers $Header -Method Post -Body (ConvertTo-Json -InputObject $body)
        }
        catch 
        {
            throw $_
        }

        Write-Verbose -Message 'Convert JSON content to PSObject (Max 64MB)'
        [void][System.Reflection.Assembly]::LoadWithPartialName('System.Web.Extensions')
        $global:result = ParseItem -jsonItem ((New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer -Property @{
                    MaxJsonLength = 67108864
        }).DeserializeObject($r.Content))
        Write-Host -Object "$($global:result.count) results have been saved to `$global:result as an array"

        if ($ToCSV)
        {
            Write-Verbose -Message 'Creating CSV'
            $CSVfilename = 'rubrik-tasks-export-'+(Get-Date).Ticks+'.csv'
            try 
            {
                foreach ($record in $global:result)
                {
                    $record | Export-Csv -Append -Path "$Home\Documents\$CSVfilename" -NoTypeInformation -Force
                }
                Write-Host -Object "CSV export written to $Home\Documents\$CSVfilename"
            }
            catch 
            {
                throw $_
            }
        }

    } # End of process
} # End of function