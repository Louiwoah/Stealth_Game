class_name HUD
extends CanvasLayer

const MESSAGE_FONT_SIZE := 24
const HINT_FONT_SIZE := 12    
const HINT_BOTTOM_GAP := 6.0    

@onready var gem_label: Label = $GemLabel
@onready var message_label: Label = $MessageLabel

var message_count := 0  

func _ready() -> void:
	message_label.visible = false

func set_gems(collected: int, total: int) -> void:
	gem_label.text = "Gems: %d / %d" % [collected, total]


func show_message(text: String, seconds: float = 0.0) -> void:
	_show(text, seconds, MESSAGE_FONT_SIZE, VERTICAL_ALIGNMENT_CENTER, 0.0)


func show_hint(text: String, seconds: float = 0.0) -> void:
	_show(text, seconds, HINT_FONT_SIZE, VERTICAL_ALIGNMENT_BOTTOM, -HINT_BOTTOM_GAP)


func _show(text: String, seconds: float, font_size: int, alignment: VerticalAlignment, bottom_offset: float) -> void:
	message_count += 1
	var this_message := message_count
	message_label.text = text
	message_label.add_theme_font_size_override("font_size", font_size)
	message_label.vertical_alignment = alignment
	message_label.offset_bottom = bottom_offset 
	message_label.visible = true
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
		if message_count == this_message: 
			message_label.visible = false
