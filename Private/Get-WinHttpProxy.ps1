Function Get-WinHttpProxy {
<# 
 .SYNOPSIS 
    function used to retrieve proxy set for local machine web layer aka winhttp 
 
.DESCRIPTION 
    retrieve proxy set for local machine web layer aka winhttp 
      
 .OUTPUTS 
        TypeName : System.Management.Automation.PSCustomObject 
 
        Name MemberType Definition 
        ---- ---------- ---------- 
        Equals Method bool Equals(System.Object obj) 
        GetHashCode Method int GetHashCode() 
        GetType Method type GetType() 
        ToString Method string ToString() 
        Winhttp proxy NoteProperty string Winhttp proxy=Direct Access 
        Winhttp proxy bypass list NoteProperty string Winhttp proxy bypass list=(none) 
        
    .EXAMPLE 
    Get all information about winhttp proxy 
    C:\PS> Get-WinHttpProxy 

    .NOTES
    Author: lucas.cueff[at]lucas-cueff.com
    Retireved from: https://www.powershellgallery.com/packages/Get-InternetAccessInfo/0.2/Content/Get-InternetAccessInfo.psm1
#>              
    [CmdletBinding()]            
    Param()                       
       try {
           $Conprx = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name WinHttpSettings).WinHttpSettings
       } catch {
            $Conprx = $null
       } finally {
            if ($Conprx) {
            $proxylength = $Conprx[12]            
                if ($proxylength -gt 0) {            
                    $proxy = -join ($Conprx[(12+3+1)..(12+3+1+$proxylength-1)] | ForEach-Object {([char]$_)})            
                    $bypasslength = $Conprx[(12+3+1+$proxylength)]            
                    if ($bypasslength -gt 0) {            
                        $bypasslist = -join ($Conprx[(12+3+1+$proxylength+3+1)..(12+3+1+$proxylength+3+1+$bypasslength)] | ForEach-Object {([char]$_)})            
                    } else {            
                        $bypasslist = '(none)'            
                    }            
                    $result = [PSCustomObject]@{
                        "Winhttp proxy" = $proxy
                        "Winhttp proxy bypass list" = $bypasslist
                    }                 
                } else {                                
                    $result = [PSCustomObject]@{
                        "Winhttp proxy" = "Direct Access"
                        "Winhttp proxy bypass list" = "(none)"
                    } 
                }
            } else {
                $result = [PSCustomObject]@{
                    "Winhttp proxy" = "error - not able to read registry entry"
                    "Winhttp proxy bypass list" = "error - not able to read registry entry"
                } 
            }
       }
       return $result                  
}