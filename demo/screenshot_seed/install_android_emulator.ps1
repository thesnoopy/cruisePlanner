param(
  [string]$Serial,
  [switch]$GenerateOnly
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$filesDir = Join-Path $scriptRoot 'files'
$generatedDir = Join-Path $scriptRoot 'generated'
$packageName = 'de.mailsmart.cruiseplanner'
$shareQueue = @()

$now = Get-Date
$anchorDay = Get-Date -Date $now.Date

function Format-LocalTimestamp {
  param([datetime]$Value)

  return $Value.ToString('yyyy-MM-ddTHH:mm:ss.fff', [System.Globalization.CultureInfo]::InvariantCulture)
}

function Format-UtcTimestamp {
  param([datetime]$Value)

  return $Value.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-AnchorTime {
  param(
    [int]$Days = 0,
    [int]$Hours = 0,
    [int]$Minutes = 0
  )

  return $anchorDay.AddDays($Days).AddHours($Hours).AddMinutes($Minutes)
}

$generatedAtUtc = Format-UtcTimestamp $now

$periodStart = Format-LocalTimestamp (Get-AnchorTime -Days -4)
$periodEnd = Format-LocalTimestamp (Get-AnchorTime -Days 4)

$excursionProvenceDate = Format-LocalTimestamp (Get-AnchorTime -Days -3 -Hours 9)
$excursionMonacoDate = Format-LocalTimestamp (Get-AnchorTime -Hours 10 -Minutes 15)
$excursionTuscanDate = Format-LocalTimestamp (Get-AnchorTime -Days 1 -Hours 8 -Minutes 30)

$paymentProvencePaidOn = Format-LocalTimestamp (Get-AnchorTime -Days -21 -Hours 10 -Minutes 15)
$paymentMonacoPaidOn = Format-LocalTimestamp (Get-AnchorTime -Days -19 -Hours 8)
$paymentTuscanPaidOn = Format-LocalTimestamp (Get-AnchorTime -Days -17 -Hours 9 -Minutes 30)
$paymentTuscanDueDate = Format-LocalTimestamp (Get-AnchorTime)

$travelOutboundFlightStart = Format-LocalTimestamp (Get-AnchorTime -Days -5 -Hours 9 -Minutes 15)
$travelOutboundFlightEnd = Format-LocalTimestamp (Get-AnchorTime -Days -5 -Hours 11 -Minutes 20)
$travelTransferHotelStart = Format-LocalTimestamp (Get-AnchorTime -Days -5 -Hours 12)
$travelTransferHotelEnd = Format-LocalTimestamp (Get-AnchorTime -Days -5 -Hours 12 -Minutes 45)
$travelHotelStart = Format-LocalTimestamp (Get-AnchorTime -Days -5 -Hours 15)
$travelHotelEnd = Format-LocalTimestamp (Get-AnchorTime -Days -4 -Hours 11)
$travelCruiseCheckInStart = Format-LocalTimestamp (Get-AnchorTime -Days -4 -Hours 12 -Minutes 30)
$travelCruiseCheckInEnd = Format-LocalTimestamp (Get-AnchorTime -Days -4 -Hours 14)
$travelCruiseCheckOutStart = Format-LocalTimestamp (Get-AnchorTime -Days 4 -Hours 7 -Minutes 30)
$travelCruiseCheckOutEnd = Format-LocalTimestamp (Get-AnchorTime -Days 4 -Hours 8 -Minutes 30)
$travelTransferAirportStart = Format-LocalTimestamp (Get-AnchorTime -Days 4 -Hours 9)
$travelTransferAirportEnd = Format-LocalTimestamp (Get-AnchorTime -Days 4 -Hours 9 -Minutes 40)
$travelReturnFlightStart = Format-LocalTimestamp (Get-AnchorTime -Days 4 -Hours 13 -Minutes 10)
$travelReturnFlightEnd = Format-LocalTimestamp (Get-AnchorTime -Days 4 -Hours 15 -Minutes 25)

$routeBarcelonaEmbarkDate = Format-LocalTimestamp (Get-AnchorTime -Days -4)
$routeBarcelonaEmbarkDeparture = Format-LocalTimestamp (Get-AnchorTime -Days -4 -Hours 18)
$routeBarcelonaEmbarkAllAboard = Format-LocalTimestamp (Get-AnchorTime -Days -4 -Hours 17 -Minutes 30)

$routeMarseilleDate = Format-LocalTimestamp (Get-AnchorTime -Days -3)
$routeMarseilleArrival = Format-LocalTimestamp (Get-AnchorTime -Days -3 -Hours 8)
$routeMarseilleDeparture = Format-LocalTimestamp (Get-AnchorTime -Days -3 -Hours 18)
$routeMarseilleAllAboard = Format-LocalTimestamp (Get-AnchorTime -Days -3 -Hours 17 -Minutes 30)

$routeSeaDayDate = Format-LocalTimestamp (Get-AnchorTime -Days -2)

$routeVillefrancheDate = Format-LocalTimestamp (Get-AnchorTime)
$routeVillefrancheArrival = Format-LocalTimestamp (Get-AnchorTime -Hours 7 -Minutes 30)
$routeVillefrancheDeparture = $null
$routeVillefrancheAllAboard = $null

$routeLivornoDate = Format-LocalTimestamp (Get-AnchorTime -Days 1)
$routeLivornoArrival = Format-LocalTimestamp (Get-AnchorTime -Days 1 -Hours 7)
$routeLivornoDeparture = Format-LocalTimestamp (Get-AnchorTime -Days 1 -Hours 19)
$routeLivornoAllAboard = Format-LocalTimestamp (Get-AnchorTime -Days 1 -Hours 18 -Minutes 30)

$routeCivitavecchiaDate = Format-LocalTimestamp (Get-AnchorTime -Days 2)
$routeCivitavecchiaArrival = Format-LocalTimestamp (Get-AnchorTime -Days 2 -Hours 7)
$routeCivitavecchiaDeparture = Format-LocalTimestamp (Get-AnchorTime -Days 2 -Hours 20)
$routeCivitavecchiaAllAboard = Format-LocalTimestamp (Get-AnchorTime -Days 2 -Hours 19 -Minutes 30)

$routePalmaDate = Format-LocalTimestamp (Get-AnchorTime -Days 3)
$routePalmaArrival = Format-LocalTimestamp (Get-AnchorTime -Days 3 -Hours 9)
$routePalmaDeparture = Format-LocalTimestamp (Get-AnchorTime -Days 3 -Hours 19)
$routePalmaAllAboard = Format-LocalTimestamp (Get-AnchorTime -Days 3 -Hours 18 -Minutes 30)

$routeBarcelonaReturnDate = Format-LocalTimestamp (Get-AnchorTime -Days 4)
$routeBarcelonaReturnArrival = Format-LocalTimestamp (Get-AnchorTime -Days 4 -Hours 6 -Minutes 30)

New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null

function Get-Sha256Hex {
  param([byte[]]$Bytes)

  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  try {
    $hashBytes = $sha256.ComputeHash($Bytes)
  } finally {
    $sha256.Dispose()
  }
  return ([System.BitConverter]::ToString($hashBytes)).Replace('-', '').ToLowerInvariant()
}

function New-DocumentRecord {
  param(
    [string]$Id,
    [string]$Kind,
    [string]$Title,
    [string]$SourceFileName,
    [string]$MimeType,
    [string]$FileExtension
  )

  $sourcePath = Join-Path $filesDir $SourceFileName
  $bytes = [System.IO.File]::ReadAllBytes($sourcePath)

  return [ordered]@{
    id = $Id
    kind = $Kind
    title = $Title
    originalFileName = $SourceFileName
    mimeType = $MimeType
    fileExtension = $FileExtension
    localRelativePath = "documents/$Id/original.$FileExtension"
    byteSize = $bytes.Length
    contentHash = Get-Sha256Hex -Bytes $bytes
    createdAt = $generatedAtUtc
    updatedAt = $generatedAtUtc
    deleted = $false
  }
}

$documents = @(
  (New-DocumentRecord -Id 'demo-doc-voyage-overview' -Kind 'pdf' -Title 'Voyage Overview' -SourceFileName 'voyage-overview.pdf' -MimeType 'application/pdf' -FileExtension 'pdf'),
  (New-DocumentRecord -Id 'demo-doc-hotel-voucher' -Kind 'pdf' -Title 'Hotel Voucher' -SourceFileName 'hotel-voucher.pdf' -MimeType 'application/pdf' -FileExtension 'pdf'),
  (New-DocumentRecord -Id 'demo-doc-monaco-confirmation' -Kind 'email' -Title 'Monaco Highlights Confirmation' -SourceFileName 'monaco-confirmation.eml' -MimeType 'message/rfc822' -FileExtension 'eml'),
  (New-DocumentRecord -Id 'demo-doc-palma-day-pass' -Kind 'image' -Title 'Palma Day Pass' -SourceFileName 'palma-day-pass.svg' -MimeType 'image/svg+xml' -FileExtension 'svg')
)

$cruisesPayload = [ordered]@{
  schemaVersion = 3
  cruises = @(
    [ordered]@{
      id = 'demo-cruise-azure-spring-escape'
      title = 'Azure Spring Escape'
      ship = [ordered]@{
        name = 'Aurora Vista'
        operatorName = 'Blue Horizon Cruises'
      }
      period = [ordered]@{
        start = $periodStart
        end = $periodEnd
      }
      cabinNumber = '1208'
      deckNumber = '12'
      deckname = 'Sunrise Deck'
      excursions = @(
        [ordered]@{
          id = 'demo-exc-provence-market'
          title = 'Provence Market and Coastal Tasting'
          date = $excursionProvenceDate
          port = 'Marseille'
          meetingPoint = 'Pier shuttle stop'
          notes = 'Small-group drive with a relaxed market visit and seaside tasting.'
          price = 89.0
          currency = 'EUR'
          stops = @(
            [ordered]@{ id = 'demo-stop-marseille-old-port'; name = 'Old Port Market Hall'; address = 'Harbor Walk, Marseille'; visited = $false },
            [ordered]@{ id = 'demo-stop-cassis-viewpoint'; name = 'Cassis Cliff Viewpoint'; address = 'Coastal Panorama Road'; visited = $false },
            [ordered]@{ id = 'demo-stop-bakery'; name = 'Seaside Tasting Room'; address = 'Marina Square'; visited = $false }
          )
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
          paymentPlan = [ordered]@{
            mode = 'fullOnBooking'
            parts = @(
              [ordered]@{
                trigger = 'onBooking'
                amount = 89.0
                dueDate = $null
                isPaid = $true
                paidOn = $paymentProvencePaidOn
                paymentMethods = @('creditCard')
                cashCurrencyPreference = $null
              }
            )
          }
        },
        [ordered]@{
          id = 'demo-exc-monaco-highlights'
          title = 'Monaco Highlights and Garden Terraces'
          date = $excursionMonacoDate
          port = 'Villefranche'
          meetingPoint = 'Tender welcome desk'
          notes = 'Elegant city highlights with time for the hilltop terraces.'
          price = 124.0
          currency = 'EUR'
          stops = @(
            [ordered]@{ id = 'demo-stop-casino-square'; name = 'Casino Square'; address = 'Central Monte Carlo'; visited = $false },
            [ordered]@{ id = 'demo-stop-prince-palace'; name = 'Prince Palace Lookout'; address = 'Upper Rock Terrace'; visited = $false },
            [ordered]@{ id = 'demo-stop-exotic-garden'; name = 'Exotic Garden Terrace'; address = 'Garden Promenade'; visited = $false }
          )
          documentIds = @('demo-doc-monaco-confirmation')
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
          paymentPlan = [ordered]@{
            mode = 'depositAndRestOnSite'
            parts = @(
              [ordered]@{
                trigger = 'onBooking'
                amount = 40.0
                dueDate = $null
                isPaid = $true
                paidOn = $paymentMonacoPaidOn
                paymentMethods = @('creditCard')
                cashCurrencyPreference = $null
              },
              [ordered]@{
                trigger = 'onSite'
                amount = 84.0
                dueDate = $null
                isPaid = $false
                paidOn = $null
                paymentMethods = @('cash', 'creditCard')
                cashCurrencyPreference = 'localOrHome'
              }
            )
          }
        },
        [ordered]@{
          id = 'demo-exc-tuscan-winery'
          title = 'Tuscan Countryside and Winery Lunch'
          date = $excursionTuscanDate
          port = 'Livorno'
          meetingPoint = 'Shore excursion lounge'
          notes = 'Scenic drive through rolling vineyards with a light tasting menu.'
          price = 149.0
          currency = 'EUR'
          stops = @(
            [ordered]@{ id = 'demo-stop-vineyard'; name = 'Hillside Vineyard'; address = 'Valley Estate Lane'; visited = $false },
            [ordered]@{ id = 'demo-stop-cellar'; name = 'Private Cellar Visit'; address = 'Estate Courtyard'; visited = $false },
            [ordered]@{ id = 'demo-stop-village'; name = 'Stone Village Square'; address = 'Old Town Piazza'; visited = $false }
          )
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
          paymentPlan = [ordered]@{
            mode = 'depositAndRestDate'
            parts = @(
              [ordered]@{
                trigger = 'onBooking'
                amount = 50.0
                dueDate = $null
                isPaid = $true
                paidOn = $paymentTuscanPaidOn
                paymentMethods = @('creditCard')
                cashCurrencyPreference = $null
              },
              [ordered]@{
                trigger = 'beforeDate'
                amount = 99.0
                dueDate = $paymentTuscanDueDate
                isPaid = $false
                paidOn = $null
                paymentMethods = @('creditCard')
                cashCurrencyPreference = $null
              }
            )
          }
        }
      )
      travel = @(
        [ordered]@{
          type = 'flight'
          id = 'demo-travel-flight-outbound'
          start = $travelOutboundFlightStart
          end = $travelOutboundFlightEnd
          from = 'Berlin (BER)'
          to = 'Barcelona (BCN)'
          notes = 'Window seats selected and one checked bag included.'
          price = 229.0
          currency = 'EUR'
          carrier = 'Skybridge Air'
          flightNo = 'SB417'
          recordLocator = 'M8Q4P2'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'transfer'
          id = 'demo-travel-transfer-hotel'
          start = $travelTransferHotelStart
          end = $travelTransferHotelEnd
          from = 'Barcelona Airport'
          to = 'Hotel Mirador Azul'
          notes = 'Shared transfer reserved with luggage assistance.'
          price = 34.0
          currency = 'EUR'
          mode = 'shuttle'
          recordLocator = 'TR-BCN-517'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'hotel'
          id = 'demo-travel-hotel-barcelona'
          start = $travelHotelStart
          end = $travelHotelEnd
          from = 'Check-in'
          to = 'Check-out'
          notes = 'Sea-view room reserved for a calm pre-cruise evening.'
          price = 198.0
          currency = 'EUR'
          company = 'Mirador Collection'
          name = 'Hotel Mirador Azul'
          location = 'Barcelona Waterfront'
          address = '14 Marina Promenade, Barcelona Waterfront'
          recordLocator = 'HM8245'
          documentIds = @('demo-doc-hotel-voucher')
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'cruisecheckin'
          id = 'demo-travel-cruise-checkin'
          start = $travelCruiseCheckInStart
          end = $travelCruiseCheckInEnd
          from = 'Barcelona Cruise Terminal'
          to = 'Aurora Vista'
          notes = 'Priority boarding window with relaxed arrival buffer.'
          price = $null
          currency = $null
          recordLocator = 'AV-EMB-1208'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'cruisecheckout'
          id = 'demo-travel-cruise-checkout'
          start = $travelCruiseCheckOutStart
          end = $travelCruiseCheckOutEnd
          from = 'Aurora Vista'
          to = 'Barcelona Cruise Terminal'
          notes = 'Self-assist disembarkation planned for an easy airport transfer.'
          price = $null
          currency = $null
          recordLocator = 'AV-DIS-1208'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'transfer'
          id = 'demo-travel-transfer-airport'
          start = $travelTransferAirportStart
          end = $travelTransferAirportEnd
          from = 'Barcelona Cruise Terminal'
          to = 'Barcelona Airport'
          notes = 'Direct ride with generous check-in time at the airport.'
          price = 39.0
          currency = 'EUR'
          mode = 'taxi'
          recordLocator = 'TR-BCN-525'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'flight'
          id = 'demo-travel-flight-return'
          start = $travelReturnFlightStart
          end = $travelReturnFlightEnd
          from = 'Barcelona (BCN)'
          to = 'Berlin (BER)'
          notes = 'Afternoon return with lounge access included.'
          price = 239.0
          currency = 'EUR'
          carrier = 'Skybridge Air'
          flightNo = 'SB418'
          recordLocator = 'M8Q4P2'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        }
      )
      route = @(
        [ordered]@{
          type = 'port'
          id = 'demo-route-barcelona-embark'
          date = $routeBarcelonaEmbarkDate
          portName = 'Barcelona'
          arrival = $null
          departure = $routeBarcelonaEmbarkDeparture
          allAboard = $routeBarcelonaEmbarkAllAboard
          notes = 'Embarkation at the waterfront terminal.'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-marseille'
          date = $routeMarseilleDate
          portName = 'Marseille'
          arrival = $routeMarseilleArrival
          departure = $routeMarseilleDeparture
          allAboard = $routeMarseilleAllAboard
          notes = 'Old Port promenade and bright market colors.'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'sea'
          id = 'demo-route-sea-day'
          date = $routeSeaDayDate
          notes = 'Spa morning, open decks, and a long sunset at sea.'
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-villefranche'
          date = $routeVillefrancheDate
          portName = 'Villefranche'
          arrival = $routeVillefrancheArrival
          departure = $routeVillefrancheDeparture
          allAboard = $routeVillefrancheAllAboard
          notes = 'Tender day with Riviera views throughout the bay.'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-livorno'
          date = $routeLivornoDate
          portName = 'Livorno'
          arrival = $routeLivornoArrival
          departure = $routeLivornoDeparture
          allAboard = $routeLivornoAllAboard
          notes = 'Gateway to rolling Tuscan countryside.'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-civitavecchia'
          date = $routeCivitavecchiaDate
          portName = 'Civitavecchia'
          arrival = $routeCivitavecchiaArrival
          departure = $routeCivitavecchiaDeparture
          allAboard = $routeCivitavecchiaAllAboard
          notes = 'Classic Rome day with a gentle evening sail-away.'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-palma'
          date = $routePalmaDate
          portName = 'Palma de Mallorca'
          arrival = $routePalmaArrival
          departure = $routePalmaDeparture
          allAboard = $routePalmaAllAboard
          notes = 'Bright cathedral views and an easy old-town stroll.'
          documentIds = @('demo-doc-palma-day-pass')
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-barcelona-return'
          date = $routeBarcelonaReturnDate
          portName = 'Barcelona'
          arrival = $routeBarcelonaReturnArrival
          departure = $null
          allAboard = $null
          notes = 'Arrival morning with self-assist disembarkation.'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        }
      )
      documentIds = @('demo-doc-voyage-overview')
      updatedAtUtc = $generatedAtUtc
      deletedAtUtc = $null
    }
  )
}

$documentStorePayload = [ordered]@{
  records = $documents
}

$cruisesPrettyJson = $cruisesPayload | ConvertTo-Json -Depth 100
$cruisesCompactJson = $cruisesPayload | ConvertTo-Json -Depth 100 -Compress
$documentStorePrettyJson = $documentStorePayload | ConvertTo-Json -Depth 100
$documentStoreCompactJson = $documentStorePayload | ConvertTo-Json -Depth 100 -Compress
$shareQueueCompactJson = '[]'

$xmlContent = @"
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
  <string name="flutter.cruises_json_v3">$([System.Security.SecurityElement]::Escape($cruisesCompactJson))</string>
  <string name="flutter.document_store_v1">$([System.Security.SecurityElement]::Escape($documentStoreCompactJson))</string>
  <string name="flutter.share_intake_queue_v1">$([System.Security.SecurityElement]::Escape($shareQueueCompactJson))</string>
</map>
"@

$cruisesJsonPath = Join-Path $generatedDir 'cruises_json_v3.json'
$documentStoreJsonPath = Join-Path $generatedDir 'document_store_v1.json'
$shareQueueJsonPath = Join-Path $generatedDir 'share_intake_queue_v1.json'
$prefsXmlPath = Join-Path $generatedDir 'FlutterSharedPreferences.xml'

[System.IO.File]::WriteAllText($cruisesJsonPath, $cruisesPrettyJson + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($documentStoreJsonPath, $documentStorePrettyJson + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($shareQueueJsonPath, $shareQueueCompactJson + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($prefsXmlPath, $xmlContent, [System.Text.UTF8Encoding]::new($false))

Write-Host "Generated:"
Write-Host "  $cruisesJsonPath"
Write-Host "  $documentStoreJsonPath"
Write-Host "  $shareQueueJsonPath"
Write-Host "  $prefsXmlPath"

if ($GenerateOnly) {
  return
}

function Invoke-Adb {
  param([string[]]$Arguments)

  $fullArguments = @()
  if ($Serial) {
    $fullArguments += @('-s', $Serial)
  }
  $fullArguments += $Arguments

  & adb @fullArguments
  if ($LASTEXITCODE -ne 0) {
    throw "adb command failed: adb $($fullArguments -join ' ')"
  }
}

function Invoke-AdbCapture {
  param([string[]]$Arguments)

  $fullArguments = @()
  if ($Serial) {
    $fullArguments += @('-s', $Serial)
  }
  $fullArguments += $Arguments

  $output = & adb @fullArguments 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "adb command failed: adb $($fullArguments -join ' ')`n$output"
  }

  return ($output -join [Environment]::NewLine)
}

$tempDeviceRoot = '/data/local/tmp/cruise_app_screenshot_seed'
$tempDeviceFiles = "$tempDeviceRoot/files"
$tempPrefsDevicePath = '/data/local/tmp/FlutterSharedPreferences.xml'

Invoke-Adb -Arguments @('shell', 'am', 'force-stop', $packageName)
Invoke-Adb -Arguments @('shell', 'mkdir', '-p', $tempDeviceFiles)
$appRoot = (Invoke-AdbCapture -Arguments @('shell', 'run-as', $packageName, 'pwd')).Trim()
if ([string]::IsNullOrWhiteSpace($appRoot)) {
  throw "Unable to determine app data directory for $packageName via run-as."
}
$appSharedPrefsDir = "$appRoot/shared_prefs"
$appPrefsPath = "$appSharedPrefsDir/FlutterSharedPreferences.xml"
$prefsCopyCommand = "run-as $packageName sh -c 'mkdir -p $appSharedPrefsDir && cp $tempPrefsDevicePath $appPrefsPath && chmod 660 $appPrefsPath'"

Write-Host "Resolved app root: $appRoot"
Write-Host "Resolved shared prefs dir: $appSharedPrefsDir"
Write-Host "Resolved prefs path: $appPrefsPath"
Write-Host "Prefs temp push path: $tempPrefsDevicePath"
Write-Host "Prefs copy shell command: $prefsCopyCommand"

Invoke-Adb -Arguments @('push', $prefsXmlPath, $tempPrefsDevicePath)
Invoke-Adb -Arguments @('shell', 'chmod', '644', $tempPrefsDevicePath)

foreach ($document in $documents) {
  $sourcePath = Join-Path $filesDir $document.originalFileName
  Invoke-Adb -Arguments @('push', $sourcePath, "$tempDeviceFiles/$($document.originalFileName)")
}

Invoke-Adb -Arguments @('shell', 'run-as', $packageName, 'mkdir', '-p', 'app_flutter/documents')
Invoke-Adb -Arguments @('shell', $prefsCopyCommand)

foreach ($document in $documents) {
  Invoke-Adb -Arguments @('shell', 'run-as', $packageName, 'mkdir', '-p', "app_flutter/documents/$($document.id)")
  Invoke-Adb -Arguments @('shell', 'run-as', $packageName, 'cp', "$tempDeviceFiles/$($document.originalFileName)", "app_flutter/$($document.localRelativePath)")
}

Invoke-AdbCapture -Arguments @('shell', 'run-as', $packageName, 'ls', '-l', $appPrefsPath) | Out-Null
$prefsVerificationCommand = "run-as $packageName sh -c 'if [ -f $appPrefsPath ] && grep -q flutter.cruises_json_v3 $appPrefsPath; then echo VERIFIED; else exit 1; fi'"
$prefsVerification = Invoke-AdbCapture -Arguments @('shell', $prefsVerificationCommand)
if ($prefsVerification -notmatch 'VERIFIED') {
  throw "Verification failed: $appPrefsPath was not installed correctly for $packageName."
}

Invoke-Adb -Arguments @('shell', 'rm', '-f', $tempPrefsDevicePath)

Invoke-Adb -Arguments @('shell', 'am', 'force-stop', $packageName)
Invoke-Adb -Arguments @('shell', 'rm', '-rf', $tempDeviceRoot)

Write-Host ''
Write-Host 'Demo data installed into the emulator.'
Write-Host "Package: $packageName"
Write-Host 'Launch the app and capture screenshots.'
