extends Area2D

var TilePosition = Vector2i(0, 0)

func _ready() -> void:
	TilePosition = GlobalScript.TILESET.local_to_map(global_position)

func _on_area_entered(area):
	if area.is_in_group("Dig Hitbox"):
		GlobalScript.TILESET.erase_cell(0, TilePosition)
