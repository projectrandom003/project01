extends Control
## Reusable, editor-authored shell for full-screen overlay menus.

@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $Margin/Panel
@onready var title_label: Label = $Margin/Panel/Root/Header/Titles/Title
@onready var subtitle_label: Label = $Margin/Panel/Root/Header/Titles/Subtitle
@onready var header_actions: HBoxContainer = $Margin/Panel/Root/Header/HeaderActions
@onready var close_button: Button = $Margin/Panel/Root/Header/CloseButton
@onready var content: VBoxContainer = $Margin/Panel/Root/Content
