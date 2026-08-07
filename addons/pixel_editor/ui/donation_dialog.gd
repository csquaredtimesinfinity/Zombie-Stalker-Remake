@tool
class_name DonationDialog
extends AcceptDialog

## Lightweight "Support this plugin" dialog.
##
## Shows static cryptocurrency donation addresses (BTC / ETH / DOGE) with
## copy-to-clipboard buttons. The dialog builds its UI in code so the scene
## file stays small and the address list is trivially editable.
##
## == Editing your addresses ==
## Replace every ADDRESS below with your real wallet.
##
## No network calls are made: this is intentionally offline-only. The user is
## responsible for verifying an address before sending funds.

# ------------------------------------------------------------------ addresses
const ADDRESS_BTC := "bc1q0spvpdk9h99y4kvegtkqxgn0t6gaa94jpelxkj"
const ADDRESS_ETH := "0x2c392db1B7ED3c581dB6B774a5987e969059c093"
const ADDRESS_DOGE := "D72eCLzxzSFVWoApUEbm5oiKqNzuTvQH1Q"
const ADDRESS_USDT_TRC20 := "TLyeczjuC2i8A4KZbiMbF27ikukXK11E1i"

const _COPY_OK_TEXT := "Copied!"

@onready var _container: VBoxContainer = $Margin/Column


func _ready() -> void:
	# Default AcceptDialog already provides an OK button; we just want Close.
	ok_button_text = "Close"
	title = "Support Pixel Editor"
	# The dialog's own minimum size is derived from its children: each child
	# requests the space it needs and Window sums it up. We only pin a minimum
	# width so the address fields stay readable; the height grows automatically.
	min_size = Vector2i(440, 0)

	_add_intro()
	_add_currency("Bitcoin (BTC)", ADDRESS_BTC, "₿")
	_add_currency("Ethereum / ERC-20", ADDRESS_ETH, "Ξ")
	_add_currency("Dogecoin (DOGE)", ADDRESS_DOGE, "Ð")
	_add_currency("USDT — Tron (TRC-20)", ADDRESS_USDT_TRC20, "₮")

	# min_size recomputation happens in popup_centered() at show time; no need
	# to trigger it here while still building the tree.


# The dialog content is built dynamically, so min_size is stale until Godot
# runs a layout pass. We open the window first, then wait one frame for the
# container to be measured, and finally snap the window to the freshly
# computed min_size. That gives the correct height on first open with no
# manual pixel math.
func popup_centered(minsize: Vector2i = Vector2i.ZERO) -> void:
	super.popup_centered(minsize)
	await get_tree().process_frame
	child_controls_changed()
	# min_size now reflects the real content height; adopt it as the size.
	size = Vector2i(maxi(size.x, min_size.x), min_size.y)


func _add_intro() -> void:
	var label := Label.new()
	label.text = "If Pixel Editor saves you time, consider supporting its development with a donation. Choose a network, copy the address, and send any amount. Thank you for your support."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(540, 0)
	_container.add_child(label)

	var sep := HSeparator.new()
	_container.add_child(sep)


func _add_currency(currency_name: String, address: String, glyph: String) -> void:
	var header := HBoxContainer.new()
	var icon := Label.new()
	icon.text = glyph
	icon.custom_minimum_size = Vector2(24, 0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title := Label.new()
	title.text = currency_name
	title.add_theme_font_size_override("font_size", 16)
	header.add_child(icon)
	header.add_child(title)
	_container.add_child(header)

	var row := HBoxContainer.new()

	var field := LineEdit.new()
	field.text = address
	field.editable = false
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.tooltip_text = "Click Copy to put this address on your clipboard."
	row.add_child(field)

	var copy_btn := Button.new()
	copy_btn.text = "Copy"
	# Capture the address so the pressed signal resolves to this entry even
	# though multiple buttons share the same handler.
	copy_btn.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(address)
		copy_btn.text = _COPY_OK_TEXT
		# Restore the label shortly so it's obvious the action worked.
		_reset_copy_label.bind(copy_btn).call_deferred()
	)
	row.add_child(copy_btn)

	_container.add_child(row)


# Restore the button text on a short timer. Bound when the Copy signal fires so
# the correct button reference is captured per-entry.
func _reset_copy_label(btn: Button) -> void:
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(btn):
		btn.text = "Copy"
