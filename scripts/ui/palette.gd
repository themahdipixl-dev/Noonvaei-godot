class_name Palette
extends RefCounted
## Shared palette for the cartoon UI. Two accent colors + ink outline + cream neutral.
## Port of src/ui/theme.js (+ the two colors App.js used directly).

## dark navy outline used across the whole UI
const INK := Color("#1d2a4d")
## soft neutral (bar background, highlights)
const CREAM := Color("#FFF6DC")
## accent 1: wheat yellow (زرد گندمی)
const WHEAT := Color("#F4C542")
const WHEAT_DARK := Color("#C9961B")
## accent 2: turquoise (فیروزه‌ای)
const TEAL := Color("#1FB5A8")
const TEAL_DARK := Color("#0F847B")

## App.js root background
const GRASS := Color("#b9d98f")
## App.js loading text color
const BROWN := Color("#6b3f1d")
