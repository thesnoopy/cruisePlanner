param(
  [string]$Serial,
  [switch]$GenerateOnly
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$filesDir = Join-Path $scriptRoot 'files'
$generatedDir = Join-Path $scriptRoot 'generated'
$packageName = 'de.mailsmart.cruiseplanner'
$generatedAtUtc = '2026-04-15T10:30:00.000Z'
$shareQueue = @()

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
  (New-DocumentRecord -Id 'demo-doc-flight-itinerary' -Kind 'pdf' -Title 'Flight Itinerary' -SourceFileName 'flight-itinerary.pdf' -MimeType 'application/pdf' -FileExtension 'pdf'),
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
        start = '2026-05-18T00:00:00.000'
        end = '2026-05-25T00:00:00.000'
      }
      cabinNumber = '1208'
      deckNumber = '12'
      deckname = 'Sunrise Deck'
      excursions = @(
        [ordered]@{
          id = 'demo-exc-provence-market'
          title = 'Provence Market and Coastal Tasting'
          date = '2026-05-19T09:00:00.000'
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
                paidOn = '2026-04-01T10:15:00.000'
                paymentMethods = @('creditCard')
                cashCurrencyPreference = $null
              }
            )
          }
        },
        [ordered]@{
          id = 'demo-exc-monaco-highlights'
          title = 'Monaco Highlights and Garden Terraces'
          date = '2026-05-20T10:15:00.000'
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
                paidOn = '2026-04-03T08:00:00.000'
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
          date = '2026-05-21T08:30:00.000'
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
                paidOn = '2026-04-05T09:30:00.000'
                paymentMethods = @('creditCard')
                cashCurrencyPreference = $null
              },
              [ordered]@{
                trigger = 'beforeDate'
                amount = 99.0
                dueDate = '2026-05-01T00:00:00.000'
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
          start = '2026-05-17T09:15:00.000'
          end = '2026-05-17T11:20:00.000'
          from = 'Berlin (BER)'
          to = 'Barcelona (BCN)'
          notes = 'Window seats selected and one checked bag included.'
          price = 229.0
          currency = 'EUR'
          carrier = 'Skybridge Air'
          flightNo = 'SB417'
          recordLocator = 'M8Q4P2'
          documentIds = @('demo-doc-flight-itinerary')
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'transfer'
          id = 'demo-travel-transfer-hotel'
          start = '2026-05-17T12:00:00.000'
          end = '2026-05-17T12:45:00.000'
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
          start = '2026-05-17T15:00:00.000'
          end = '2026-05-18T11:00:00.000'
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
          start = '2026-05-18T12:30:00.000'
          end = '2026-05-18T14:00:00.000'
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
          start = '2026-05-25T07:30:00.000'
          end = '2026-05-25T08:30:00.000'
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
          start = '2026-05-25T09:00:00.000'
          end = '2026-05-25T09:40:00.000'
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
          start = '2026-05-25T13:10:00.000'
          end = '2026-05-25T15:25:00.000'
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
          date = '2026-05-18T00:00:00.000'
          portName = 'Barcelona'
          arrival = $null
          departure = '2026-05-18T18:00:00.000'
          allAboard = '2026-05-18T17:30:00.000'
          notes = 'Embarkation at the waterfront terminal.'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-marseille'
          date = '2026-05-19T00:00:00.000'
          portName = 'Marseille'
          arrival = '2026-05-19T08:00:00.000'
          departure = '2026-05-19T18:00:00.000'
          allAboard = '2026-05-19T17:30:00.000'
          notes = 'Old Port promenade and bright market colors.'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-villefranche'
          date = '2026-05-20T00:00:00.000'
          portName = 'Villefranche'
          arrival = '2026-05-20T07:30:00.000'
          departure = '2026-05-20T20:00:00.000'
          allAboard = '2026-05-20T19:30:00.000'
          notes = 'Tender day with Riviera views throughout the bay.'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-livorno'
          date = '2026-05-21T00:00:00.000'
          portName = 'Livorno'
          arrival = '2026-05-21T07:00:00.000'
          departure = '2026-05-21T19:00:00.000'
          allAboard = '2026-05-21T18:30:00.000'
          notes = 'Gateway to rolling Tuscan countryside.'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-civitavecchia'
          date = '2026-05-22T00:00:00.000'
          portName = 'Civitavecchia'
          arrival = '2026-05-22T07:00:00.000'
          departure = '2026-05-22T20:00:00.000'
          allAboard = '2026-05-22T19:30:00.000'
          notes = 'Classic Rome day with a gentle evening sail-away.'
          documentIds = @()
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'sea'
          id = 'demo-route-sea-day'
          date = '2026-05-23T00:00:00.000'
          notes = 'Spa morning, open decks, and a long sunset at sea.'
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-palma'
          date = '2026-05-24T00:00:00.000'
          portName = 'Palma de Mallorca'
          arrival = '2026-05-24T09:00:00.000'
          departure = '2026-05-24T19:00:00.000'
          allAboard = '2026-05-24T18:30:00.000'
          notes = 'Bright cathedral views and an easy old-town stroll.'
          documentIds = @('demo-doc-palma-day-pass')
          updatedAtUtc = $generatedAtUtc
          deletedAtUtc = $null
        },
        [ordered]@{
          type = 'port'
          id = 'demo-route-barcelona-return'
          date = '2026-05-25T00:00:00.000'
          portName = 'Barcelona'
          arrival = '2026-05-25T06:30:00.000'
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

$tempDeviceRoot = '/sdcard/Download/cruise_app_screenshot_seed'
$tempDeviceFiles = "$tempDeviceRoot/files"

Invoke-Adb -Arguments @('shell', 'am', 'force-stop', $packageName)
Invoke-Adb -Arguments @('shell', 'mkdir', '-p', $tempDeviceFiles)
Invoke-Adb -Arguments @('push', $prefsXmlPath, "$tempDeviceRoot/FlutterSharedPreferences.xml")

foreach ($document in $documents) {
  $sourcePath = Join-Path $filesDir $document.originalFileName
  Invoke-Adb -Arguments @('push', $sourcePath, "$tempDeviceFiles/$($document.originalFileName)")
}

Invoke-Adb -Arguments @('shell', 'run-as', $packageName, 'mkdir', '-p', 'shared_prefs')
Invoke-Adb -Arguments @('shell', 'run-as', $packageName, 'mkdir', '-p', 'app_flutter/documents')
Invoke-Adb -Arguments @('shell', 'run-as', $packageName, 'cp', "$tempDeviceRoot/FlutterSharedPreferences.xml", 'shared_prefs/FlutterSharedPreferences.xml')

foreach ($document in $documents) {
  Invoke-Adb -Arguments @('shell', 'run-as', $packageName, 'mkdir', '-p', "app_flutter/documents/$($document.id)")
  Invoke-Adb -Arguments @('shell', 'run-as', $packageName, 'cp', "$tempDeviceFiles/$($document.originalFileName)", "app_flutter/$($document.localRelativePath)")
}

Invoke-Adb -Arguments @('shell', 'am', 'force-stop', $packageName)

Write-Host ''
Write-Host 'Demo data installed into the emulator.'
Write-Host "Package: $packageName"
Write-Host 'Launch the app and capture screenshots.'
