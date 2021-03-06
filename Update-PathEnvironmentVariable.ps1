function Update-PathEnvironmentVariable {
  param (
    [string]
    $NewPath = '',
    [switch]
    $UpdateRegistry
  )
  $newPathExists = $false
  $result = $null
  $result = REG QUERY 'HKLM\System\CurrentControlSet\Control\Session Manager\Environment' /V PATH
  $PathRegistryEnvString = $null
  $result |
    ForEach-Object {
      if(!([string]::IsNullOrEmpty($_) -or $_ -match 'HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment')) {
        $PathRegistryEnvString += $_
      }
    }
  $PathRegistryEnvString = $PathRegistryEnvString -replace '^\s*PATH\s*REG_EXPAND_SZ\s*', ''
  $PathRegistryEnvString = $PathRegistryEnvString -replace ';;', ';'
  $PathRegistryEnvStringSplit = $null
  $PathRegistryEnvStringSplit = ($PathRegistryEnvString | Select-Object -Unique) -split ';' | Sort-Object
  $NewRegistryEnvString = $null
  $PathRegistryEnvStringSplit | ForEach-Object {
    if ($_ -match '%[A-Za-z]*%') {
      $pathToTest = $_
      do {
        $replaceString = $Matches[0]
        $envVariableName = $replaceString -replace '%', ''
        $newString = [Environment]::GetEnvironmentVariable($envVariableName)
        $pathToTest = $pathToTest -replace $replaceString, $newString
      } until (($pathToTest -match '%[A-Za-z]*%') -eq $false)
    } else {
      $pathToTest = $_
    }
    if ($pathToTest -eq $NewPath -and $NewPath.Length -gt 0) {
      $newPathExists = $true
    }
    if (Test-Path -Path $pathToTest) {
      $NewRegistryEnvString += "$_;"
    }
  }
  $NewRegistryEnvStringSplit = $NewRegistryEnvString -split ';'
  if ($newPathExists -eq $false) {
    $NewRegistryEnvStringSplit += $NewPath
  }
  $NewRegistryEnvStringSplit = $NewRegistryEnvStringSplit | Where-Object { $_ -ne '' } | Sort-Object
  $NewRegistryEnvString = $NewRegistryEnvStringSplit -join ';'
  # $NewRegistryEnvString
  if ($UpdateRegistry) {
    # Set the registry key
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $NewRegistryEnvString
    $result = REG QUERY 'HKLM\System\CurrentControlSet\Control\Session Manager\Environment' /V PATH
    $PathRegistryEnvString = $null
    $result |
      ForEach-Object {
        if(!([string]::IsNullOrEmpty($_) -or $_ -match 'HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment')) {
          $PathRegistryEnvString += $_
        }
      }
    $PathRegistryEnvString = $PathRegistryEnvString -replace '^\s*PATH\s*REG_EXPAND_SZ\s*', ''
    $PathRegistryEnvString = $PathRegistryEnvString -replace ';;', ';'
    $PathRegistryEnvString
  } else {
    # Update current environment only
    $env:PATH = $NewRegistryEnvString
    $env:PATH
  }
}
