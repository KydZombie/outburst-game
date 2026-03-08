extends Node

# Global signals used by card UI. Emitted by card states / target selector.
@warning_ignore_start("unused_signal")
signal card_aim_started(card_ui)
signal card_aim_ended(card_ui)
@warning_ignore_restore("unused_signal")
