﻿using module ..\Include.psm1

$Path = ".\Bin\NeoScrypt-Claymore\NeoScryptMiner.exe"
$URI = "https://github.com/RainbowMiner/miner-binaries/releases/download/v1.2-claymoreneoscrypt/claymore_neoscrypt_1.2.zip"
$Port = "202{0:d2}"

$Devices = $Devices.AMD
if (-not $Devices -or $Config.InfoOnly) {return} # No AMD present in system

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{MainAlgorithm = "neoscrypt"; Params = ""} #NeoScrypt
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Devices | Select-Object Vendor, Model -Unique | ForEach-Object {
    $Miner_Device = $Devices | Where-Object Vendor -EQ $_.Vendor | Where-Object Model -EQ $_.Model
    $Miner_Port = $Port -f ($Miner_Device | Select-Object -First 1 -ExpandProperty Index)
    $Miner_Model = $_.Model
    $Miner_Name = (@($Name) + @($Miner_Device.Name | Sort-Object) | Select-Object) -join '-'

    $DeviceIDsAll = Get-GPUIDs $Miner_Device -join ','

    $Commands | Where-Object {$Pools.(Get-Algorithm $_.MainAlgorithm).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

        $Algorithm_Norm = Get-Algorithm $_.MainAlgorithm

        [PSCustomObject]@{
            Name = $Miner_Name
            DeviceName = $Miner_Device.Name
            DeviceModel = $Miner_Model
            Path = $Path
            Arguments = "-r -1 -mport $($Miner_Port) -zpool $($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -wal $($Pools.$Algorithm_Norm.User) -psw $($Pools.$Algorithm_Norm.Pass) -di $($DeviceIDsAll) $($_.Params)"
            HashRates = [PSCustomObject]@{$Algorithm_Norm = $Stats."$($Miner_Name)_$($Algorithm_Norm)_HashRate".Week }
            API = "Claymore"
            Port = $Miner_Port
            URI = $Uri
        }
    }
}