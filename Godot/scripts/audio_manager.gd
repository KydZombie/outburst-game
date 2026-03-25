class_name AudioManager
extends Node

func play_card() -> void:
	var p := $SFX_PlayCard
	if p:
		p.play()

func draw_card() -> void:
	var p := $SFX_DrawCard
	if p:
		p.play()

func hover_card() -> void:
	var p := $SFX_CardHover
	if p:
		p.play()


func play_enemy_attack_hit() -> void:
	var p: AudioStreamPlayer = get_node_or_null("SFX_EnemyAttack") as AudioStreamPlayer
	if p:
		p.play()

