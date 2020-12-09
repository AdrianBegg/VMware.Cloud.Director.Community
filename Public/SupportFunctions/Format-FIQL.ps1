function Format-FIQL(){
    <#
    .SYNOPSIS
    Takes a HashTable of one or more filters in the format "Value" = "Expression" and returns a string formatted as an FIQL Query

    .DESCRIPTION
    Takes a HashTable of one or more filters in the format "Value" = "Expression" and returns a string formatted as an FIQL Query

    .PARAMETER Parameters
    Hashtable of Expressions

    .EXAMPLE
    An example

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-11
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [Hashtable] $Parameters
    )
    if($Parameters.Count -eq 1){
        # For a single value just return the Key and the value
        return [string] "$($Parameters.Keys)$($Parameters.Values)"
    } else {
        [string] $Result = "(" #Initalise a string and open the statement
        foreach($Filter in $Parameters.Keys){
            $Result += "$Filter$($Parameters.$Filter);"
        }
        # Remove the trailing ; and close the statement
        $Result = "$($Result.TrimEnd(";")))"
        return $Result
    }
}