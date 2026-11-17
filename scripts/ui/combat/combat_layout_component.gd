class_name CombatLayoutComponent
extends Node
## Binds authored combat presentation and configures combat HUD styling.


var screen


func bind(owner_screen) -> void:
	screen = owner_screen


func build() -> void:
	if screen == null:
		return
	if screen.get_node_or_null("CombatScreenBackdrop") == null:
		push_error("CombatScreen requires its authored backdrop scene.")
		return
	if screen.get_node_or_null("CombatScreenLayout") == null:
		push_error("CombatScreen requires its authored layout scene.")
		return
	build_layout()

func build_background() -> void:
	if screen != null and screen.get_node_or_null("CombatScreenBackdrop") == null:
		push_error("CombatScreenBackdrop must be authored in combat_screen.tscn.")


func style_combat_panel(panel: PanelContainer, fill: Color, radius: int, margin: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = UITheme.BORDER_SOFT
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	panel.add_theme_stylebox_override("panel", style)



func build_layout() -> void:
	# Bind only the static layout authored in combat_screen_layout.tscn.
	var layout := screen.get_node_or_null("CombatScreenLayout") as Control
	if layout == null:
		push_error("CombatScreenLayout is not authored under CombatScreen.")
		return
	var root := layout.get_node("Root") as VBoxContainer
	var header := root.get_node("CombatHeader") as HBoxContainer
	screen._title_label = header.get_node("TitleLabel") as Label
	screen._title_label.add_theme_font_size_override("font_size", 20)
	screen._title_label.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	screen._round_label = header.get_node("RoundLabel") as Label
	screen._round_label.add_theme_font_size_override("font_size", 10)
	screen._round_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	screen._auto_button = header.get_node("AutoButton") as Button
	screen._auto_button.add_theme_stylebox_override("normal", UIFactory.button_stylebox())
	screen._auto_button.toggled.connect(screen._on_auto_toggled)
	screen._speed_button = header.get_node("SpeedButton") as Button
	screen._speed_button.add_theme_stylebox_override("normal", UIFactory.button_stylebox())
	screen._speed_button.pressed.connect(screen._cycle_speed)
	var retreat := header.get_node("RetreatButton") as Button
	retreat.add_theme_stylebox_override("normal", UIFactory.button_stylebox(false, true))
	retreat.pressed.connect(screen._confirm_retreat)

	screen._boss_bar_container = root.get_node("BossHealthPanel") as VBoxContainer
	screen._boss_name_label = screen._boss_bar_container.get_node("Panel/Content/BossName") as Label
	screen._boss_name_label.add_theme_font_size_override("font_size", 16)
	screen._boss_name_label.add_theme_color_override("font_color", UITheme.DANGER)
	screen._boss_hp_bar = screen._boss_bar_container.get_node("Panel/Content/HealthBar") as ProgressBar
	screen._boss_hp_bar.add_theme_stylebox_override("fill", UIFactory.bar_fill_style(UITheme.DANGER))
	screen._boss_phase_label = screen._boss_bar_container.get_node("Panel/Content/PhaseLabel") as Label
	screen._boss_phase_label.add_theme_font_size_override("font_size", 9)
	screen._boss_phase_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	var boss_panel_style := StyleBoxFlat.new()
	boss_panel_style.bg_color = Color("#1a0a0a")
	boss_panel_style.border_color = Color(UITheme.DANGER.r, UITheme.DANGER.g, UITheme.DANGER.b, 0.6)
	boss_panel_style.set_border_width_all(1)
	boss_panel_style.set_corner_radius_all(8)
	boss_panel_style.content_margin_left = 6
	boss_panel_style.content_margin_right = 6
	boss_panel_style.content_margin_top = 6
	boss_panel_style.content_margin_bottom = 6
	(screen._boss_bar_container.get_node("Panel") as PanelContainer).add_theme_stylebox_override("panel", boss_panel_style)

	var turn_panel := root.get_node("TurnOrderPanel") as PanelContainer
	var turn_style := StyleBoxFlat.new()
	turn_style.bg_color = Color(0.05, 0.075, 0.13, 0.7)
	turn_style.border_color = UITheme.BORDER_SOFT
	turn_style.set_border_width_all(1)
	turn_style.set_corner_radius_all(6)
	turn_style.content_margin_left = 4
	turn_style.content_margin_right = 4
	turn_style.content_margin_top = 4
	turn_style.content_margin_bottom = 4
	turn_panel.add_theme_stylebox_override("panel", turn_style)
	var turn_caption := turn_panel.get_node("TurnRow/Caption") as Label
	turn_caption.add_theme_font_size_override("font_size", 8)
	turn_caption.add_theme_color_override("font_color", UITheme.TEXT_FAINT)
	screen._turn_box = turn_panel.get_node("TurnRow/TurnItems") as HBoxContainer

	screen._battlefield = root.get_node("Battlefield") as Battlefield
	screen._battlefield.arena_id = screen.group_id
	screen._battlefield.actor_clicked.connect(screen._on_battlefield_actor_clicked)
	screen._battlefield.cinematic_impact.connect(screen._camera_shake)

	var bottom := root.get_node("CombatBottomHUD") as HBoxContainer
	var info_panel := bottom.get_node("ActiveInfoPanel") as PanelContainer
	var roster_panel := bottom.get_node("RosterPanel") as PanelContainer
	var skills_panel := bottom.get_node("SkillsPanel") as PanelContainer
	var log_panel := bottom.get_node("LogPanel") as PanelContainer
	style_combat_panel(info_panel, Color("#0b1220"), 8, 8)
	style_combat_panel(roster_panel, Color("#0b1220"), 8, 8)
	style_combat_panel(skills_panel, Color("#0b1220"), 8, 8)
	style_combat_panel(log_panel, Color("#0a101c"), 8, 6)

	screen._actor_label = bottom.get_node("ActiveInfoPanel/InfoContent/ActorLabel") as Label
	screen._actor_label.add_theme_font_size_override("font_size", 14)
	screen._actor_label.add_theme_color_override("font_color", UITheme.TEXT)
	screen._hp_bar = bottom.get_node("ActiveInfoPanel/InfoContent/HPBar") as ProgressBar
	screen._hp_bar.add_theme_stylebox_override("fill", UIFactory.bar_fill_style(UITheme.GREEN))
	screen._energy_bar = bottom.get_node("ActiveInfoPanel/InfoContent/EnergyBar") as ProgressBar
	screen._energy_bar.add_theme_stylebox_override("fill", UIFactory.bar_fill_style(UITheme.GOLD))
	screen._status_label = bottom.get_node("ActiveInfoPanel/InfoContent/StatusLabel") as Label
	screen._status_label.add_theme_font_size_override("font_size", 9)
	screen._status_label.add_theme_color_override("font_color", UITheme.TEAL)

	var roster_caption := bottom.get_node("RosterPanel/RosterContent/RosterCaption") as Label
	roster_caption.add_theme_font_size_override("font_size", 8)
	roster_caption.add_theme_color_override("font_color", UITheme.TEXT_FAINT)
	screen._roster_box = bottom.get_node("RosterPanel/RosterContent/RosterItems") as VBoxContainer

	screen._skills_box = bottom.get_node("SkillsPanel/SkillsContent/SkillItems") as HFlowContainer
	screen._hint_label = bottom.get_node("SkillsPanel/SkillsContent/HintLabel") as Label
	screen._hint_label.add_theme_font_size_override("font_size", 10)
	screen._hint_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)

	var log_caption := bottom.get_node("LogPanel/LogContent/LogCaption") as Label
	log_caption.add_theme_font_size_override("font_size", 8)
	log_caption.add_theme_color_override("font_color", UITheme.TEXT_FAINT)
	screen._log_label = bottom.get_node("LogPanel/LogContent/LogText") as RichTextLabel
	screen._log_label.add_theme_font_size_override("normal_font_size", 9)
	screen._log_label.add_theme_color_override("default_color", UITheme.TEXT_DIM)

