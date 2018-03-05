# Requires -Version 3
Function Get-VcXml {
    <#
    .SYNOPSIS
        Creates and array of Visual C++ Redistributables listed in an external XML file.

    .DESCRIPTION
        This script will download the Visual C++ Redistributables listed in an external XML file into a folder structure that represents release and processor architecture.
        If the redistributable exists in the specified path, it will not be re-downloaded.

        A complete XML file listing the redistributables is included. The basic structure of the XML file should be:

        <Redistributables>
            <Platform Architecture="x64" Release="" Install="">
                <Redistributable>
                    <Name></Name>
                    <ShortName></ShortName>
                    <URL></URL>
                    <ProductCode></ProductCode>
                    <Download></Download>
            </Platform>
            <Platform Architecture="x86" Release="" Install="">
                <Redistributable>
                    <Name></Name>
                    <ShortName></ShortName>
                    <URL></URL>
                    <ProductCode></ProductCode>
                    <Download></Download>
                </Redistributable>
            </Platform>
        </Redistributables>

    .OUTPUTS
         System.Array
    
    .NOTES
        Name: Get-VcXml
        Author: Aaron Parker
        Twitter: @stealthpuppy

    .LINK
        http://stealthpuppy.com

    .PARAMETER Xml
        The XML file that contains the details about the Visual C++ Redistributables. This must be in the expected format.

    .EXAMPLE
        .\Get-VcXml -Xml ".\VisualCRedistributablesSupported.xml"

        Description:
        Build an array of the Visual C++ Redistributables listed in VisualCRedistributablesSupported.xml.
#>
    [CmdletBinding(SupportsShouldProcess = $False)]
    Param (
        [Parameter(Mandatory = $False, HelpMessage = "Path to the XML document describing the Redistributables.")]
        [ValidateNotNull()]
        [ValidateScript({ If (Test-Path $_ -PathType 'Leaf') { $True } Else { Throw "Cannot find file $_" } })]
        [string]$Xml = "$($MyInvocation.MyCommand.Module.ModuleBase)\VisualCRedistributablesSupported.xml"
    )
    Begin {
        # The array that will be returned
        $Output = @()
    }
    Process {
        # Read the specifed XML document
        Try {
            Write-Verbose "Reading XML document $Xml."
            [xml]$xmlDocument = Get-Content -Path $Xml -ErrorVariable xmlReadError -ErrorAction SilentlyContinue
        }
        Catch {
            Throw "Unable to read $Xml. $xmlReadError"
        }

        # Build the output object by compiling an array of each redistributable
        $xmlContent = (Select-Xml -XPath "/Redistributables/Platform" -Xml $xmlDocument).Node
        ForEach ($platform in $xmlContent) {
            Write-Verbose "Building array with $($platform.Release) on $($platform.Architecture)."
            ForEach ($redistributable in $platform.Redistributable) {
                Write-Verbose "Adding to array with $($redistributable.Name)"
                $item = New-Object PSObject
                $item | Add-Member -Type NoteProperty -Name 'Name' -Value $redistributable.Name
                $item | Add-Member -Type NoteProperty -Name 'ShortName' -Value $redistributable.ShortName
                $item | Add-Member -Type NoteProperty -Name 'URL' -Value $redistributable.URL
                $item | Add-Member -Type NoteProperty -Name 'ProductCode' -Value $redistributable.ProductCode
                $item | Add-Member -Type NoteProperty -Name 'Download' -Value $redistributable.Download
                $item | Add-Member -Type NoteProperty -Name 'Release' -Value $platform.Release
                $item | Add-Member -Type NoteProperty -Name 'Architecture' -Value $platform.Architecture
                $Output += $item
            }
        }
    }
    End {
        # Return array to the pipeline
        $Output
    }
}