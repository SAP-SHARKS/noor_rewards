#!/usr/bin/env pwsh
# Generates the SQL migration from _azkar_review.csv.

$ErrorActionPreference = 'Stop'

$csvPath = "D:\noor_rewards-main\noor_rewards-main\_azkar_review.csv"
$sqlPath = "D:\noor_rewards-main\noor_rewards-main\supabase\migrations\20260603_010_azkar_screenshots_import.sql"

$catMap = @{
  'Duas before Sleep'    = @{ id = 'duas_before_sleep';    sort = 100; idPrefix = 'sleep_before'; icon = 'bedtime_rounded' }
  'Duas after Salah'     = @{ id = 'duas_after_salah';     sort = 110; idPrefix = 'salah_after';  icon = 'mosque_rounded' }
  'Daily Duas'           = @{ id = 'daily_duas';           sort = 120; idPrefix = 'daily_dua';    icon = 'auto_awesome_rounded' }
  'Remembrance of Allah' = @{ id = 'remembrance_of_allah'; sort = 130; idPrefix = 'dhikr';        icon = 'auto_awesome_rounded' }
  '40 Rabbana Duas'      = @{ id = 'rabbana_40';           sort = 140; idPrefix = 'rabbana';      icon = 'bookmark_rounded' }
  'Ruquiya'              = @{ id = 'ruquiya';              sort = 150; idPrefix = 'ruquiya';      icon = 'shield_rounded' }
}

function Esc-Sql([string]$s) {
  if ([string]::IsNullOrEmpty($s)) { return 'NULL' }
  return "'" + ($s -replace "'", "''") + "'"
}

function Parse-Count([string]$raw) {
  if ([string]::IsNullOrWhiteSpace($raw)) { return @{ n = 1; label = $null } }
  $trimmed = $raw.Trim()
  if ($trimmed -match '^\d+$') { return @{ n = [int]$trimmed; label = $null } }
  if ($trimmed -match '^\d+(\+\d+)+$') {
    $sum = 0
    ($trimmed -split '\+') | ForEach-Object { $sum += [int]$_ }
    return @{ n = $sum; label = $trimmed }
  }
  return @{ n = 1; label = $trimmed }
}

$rows = Import-Csv -Path $csvPath -Encoding UTF8

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("-- =============================================================================")
$lines.Add("-- 20260603_010_azkar_screenshots_import")
$lines.Add("--")
$lines.Add("-- Imports azkar extracted from the 'Dua and Adhkar' reference app screenshots.")
$lines.Add("-- Touches ONLY these 6 categories (Morning/Evening are explicitly preserved):")
$lines.Add("--   duas_before_sleep, duas_after_salah, daily_duas,")
$lines.Add("--   remembrance_of_allah, rabbana_40, ruquiya")
$lines.Add("--")
$lines.Add("-- Adds two columns to azkar_items:")
$lines.Add("--   title                    TEXT - display name (e.g. 'When Sneezing')")
$lines.Add("--   recommended_count_label  TEXT - non-numeric counts (e.g. '33+33+34')")
$lines.Add("-- =============================================================================")
$lines.Add("")
$lines.Add("BEGIN;")
$lines.Add("")
$lines.Add("-- 1. Schema additions ------------------------------------------------------")
$lines.Add("ALTER TABLE azkar_items ADD COLUMN IF NOT EXISTS title TEXT;")
$lines.Add("ALTER TABLE azkar_items ADD COLUMN IF NOT EXISTS recommended_count_label TEXT;")
$lines.Add("")
$lines.Add("-- 2. Upsert categories ----------------------------------------------------")
$lines.Add("INSERT INTO azkar_categories (id, label, icon_name, sort_order, is_visible) VALUES")
$catRows = @()
foreach ($cat in $catMap.GetEnumerator() | Sort-Object { $_.Value.sort }) {
  $catRows += "  ($(Esc-Sql $cat.Value.id), $(Esc-Sql $cat.Key), $(Esc-Sql $cat.Value.icon), $($cat.Value.sort), true)"
}
$lines.Add(($catRows -join ",`n"))
$lines.Add("ON CONFLICT (id) DO UPDATE SET")
$lines.Add("  label      = EXCLUDED.label,")
$lines.Add("  icon_name  = EXCLUDED.icon_name,")
$lines.Add("  sort_order = EXCLUDED.sort_order,")
$lines.Add("  is_visible = EXCLUDED.is_visible;")
$lines.Add("")
$lines.Add("-- 3. Wipe existing rows in the 6 target categories ----------------------")
$lines.Add("-- (Morning/Evening intentionally excluded.)")
$catIdList = ($catMap.Values | ForEach-Object { Esc-Sql $_.id }) -join ', '
$lines.Add("DELETE FROM azkar_item_categories WHERE category_id IN ($catIdList);")
$lines.Add("DELETE FROM azkar_items WHERE category_id IN ($catIdList);")
$lines.Add("")
$lines.Add("-- 4. Insert azkar items --------------------------------------------------")
$lines.Add("INSERT INTO azkar_items")
$lines.Add("  (id, title, arabic, transliteration, translation,")
$lines.Add("   recommended_count, recommended_count_label, category_id,")
$lines.Add("   reward, reference, sort_order, hadith_full)")
$lines.Add("VALUES")

$insertLines = @()
$junctionLines = @()
foreach ($r in $rows) {
  if (-not $catMap.ContainsKey($r.category)) {
    Write-Warning "Skipping unknown category: $($r.category)"
    continue
  }
  $cat = $catMap[$r.category]
  $seq = [int]$r.sequence
  $id = "{0}_{1:D3}" -f $cat.idPrefix, $seq
  $count = Parse-Count $r.recommended_count

  $insertLines += "  ($(Esc-Sql $id), $(Esc-Sql $r.subtitle), $(Esc-Sql $r.arabic), $(Esc-Sql $r.transliteration), $(Esc-Sql $r.translation), $($count.n), $(Esc-Sql $count.label), $(Esc-Sql $cat.id), $(Esc-Sql $r.benefit), $(Esc-Sql $r.reference), $seq, $(Esc-Sql $r.benefit))"
  $junctionLines += "  ($(Esc-Sql $id), $(Esc-Sql $cat.id), $seq)"
}

$lines.Add(($insertLines -join ",`n"))
$lines.Add(";")
$lines.Add("")
$lines.Add("-- 5. Junction backfill (azkar_item_categories) -------------------------")
$lines.Add("INSERT INTO azkar_item_categories (azkar_id, category_id, sort_order) VALUES")
$lines.Add(($junctionLines -join ",`n"))
$lines.Add("ON CONFLICT (azkar_id, category_id) DO UPDATE SET sort_order = EXCLUDED.sort_order;")
$lines.Add("")
$lines.Add("-- 6. Verify --------------------------------------------------------------")
$lines.Add("SELECT category_id, COUNT(*) AS item_count")
$lines.Add("FROM azkar_items")
$lines.Add("WHERE category_id IN ($catIdList)")
$lines.Add("GROUP BY category_id")
$lines.Add("ORDER BY category_id;")
$lines.Add("")
$lines.Add("-- Sanity: morning/evening counts must be unchanged from before this migration.")
$lines.Add("SELECT category_id, COUNT(*) AS item_count")
$lines.Add("FROM azkar_items")
$lines.Add("WHERE category_id IN ('morning', 'evening')")
$lines.Add("GROUP BY category_id")
$lines.Add("ORDER BY category_id;")
$lines.Add("")
$lines.Add("COMMIT;")

[System.IO.File]::WriteAllText($sqlPath, ($lines -join "`r`n"), [System.Text.UTF8Encoding]::new($false))
"Generated: $sqlPath"
"Total INSERT rows: $($insertLines.Count)"
"Total junction rows: $($junctionLines.Count)"
"SQL file size: $((Get-Item $sqlPath).Length) bytes"
