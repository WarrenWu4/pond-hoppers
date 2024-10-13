extends CanvasLayer

@onready var timer_label = $TimerLabel

func update_timer(min, sec):
	var minText = str(min)
	if (min < 10):
		minText = "0" + minText
	var secText = str(sec)
	if (sec < 10):
		secText = "0" + secText
	timer_label.set_text(minText+":"+secText)
