class_name EdgarNPC
extends WorldNPC
## Dedicated node-based scene identity for Edgar, Greenward's Market Keeper.
## Dialogue and quest state remain data-driven through the existing WorldNPC API.

const EDGAR_ID := "edgar_market_keeper"
const EDGAR_NAME := "Edgar"
const EDGAR_DIALOGUE := "edgar_market_keeper"
const EDGAR_PALETTE := {
	"hair": "#34231f",
	"primary": "#49202d",
	"secondary": "#c9a45a",
	"accent": "#e4c98c",
	"skin": "#e6c3a8",
}


func _ready() -> void:
	if npc_id.is_empty():
		setup(EDGAR_ID, EDGAR_NAME, EDGAR_DIALOGUE, EDGAR_PALETTE, "Human")
	role = "Market Keeper"
	quest_marker_y = -178.0
	super._ready()
