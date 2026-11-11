param(
    [string] $WebConfigPath = (Join-Path $PSScriptRoot '../config/firebase_web.local.json'),
    [string] $AndroidConfigPath = (Join-Path $PSScriptRoot '../android/app/google-services.json')
)
$ErrorActionPreference = 'Stop'
# Only status/field names are printed, never configuration values or parse errors.
try {
    if (!(Test-Path -LiteralPath $WebConfigPath) -or !(Test-Path -LiteralPath $AndroidConfigPath)) {
        throw 'missing-files'
    }
    $webConfig = Get-Content -LiteralPath $WebConfigPath -Raw | ConvertFrom-Json
    $androidConfig = Get-Content -LiteralPath $AndroidConfigPath -Raw | ConvertFrom-Json
    $requiredFields = @('FIREBASE_WEB_API_KEY', 'FIREBASE_WEB_APP_ID',
        'FIREBASE_WEB_MESSAGING_SENDER_ID', 'FIREBASE_WEB_PROJECT_ID', 'FIREBASE_WEB_AUTH_DOMAIN')
    $missing = @($requiredFields | Where-Object {
        $value = $webConfig.$_
        $value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)
    })
    if ($missing.Count -gt 0) {
        Write-Output ('Campos Web ausentes: ' + ($missing -join ', '))
        exit 1
    }
    $spaces = @($requiredFields | Where-Object { $webConfig.$_ -cne $webConfig.$_.Trim() })
    if ($spaces.Count -gt 0) { throw 'invalid-whitespace' }
    $webId = [regex]::Match($webConfig.FIREBASE_WEB_APP_ID, '^1:([0-9]+):web:[A-Za-z0-9]+$')
    $domain = $null
    $domainValid = [Uri]::TryCreate(('https://' + $webConfig.FIREBASE_WEB_AUTH_DOMAIN), [UriKind]::Absolute, [ref]$domain)
    if (!$webId.Success -or !$domainValid -or $domain.Host -cne $webConfig.FIREBASE_WEB_AUTH_DOMAIN -or
        $domain.UserInfo -ne '' -or $domain.Authority -cne $domain.Host -or $domain.AbsolutePath -ne '/' -or !$domain.IsDefaultPort -or
        $domain.Query -ne '' -or $domain.Fragment -ne '') {
        throw 'invalid-client-configuration'
    }
    $sameProject = $webConfig.FIREBASE_WEB_PROJECT_ID -ceq $androidConfig.project_info.project_id
    $sameNumber = $webId.Groups[1].Value -ceq [string]$androidConfig.project_info.project_number
    $sameSender = $webConfig.FIREBASE_WEB_MESSAGING_SENDER_ID -ceq [string]$androidConfig.project_info.project_number
    if (!$sameProject -or !$sameNumber -or !$sameSender) { throw 'project-mismatch' }
    Write-Output 'Configuración local completa: appId Web, proyecto y número de proyecto coinciden con Android.'
    Write-Output 'La comprobación es local; no valida registro en Console, API key, dominios autorizados ni conectividad.'
} catch {
    Write-Output 'No se pudo validar Firebase Web. Revisa archivos locales, campos y coincidencia con Android. No se mostraron valores.'
    exit 1
}
