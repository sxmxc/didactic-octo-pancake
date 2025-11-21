extends Panel

@onready var time_label = %TimeLabel
@onready var date_label = %DateLabel

var month_dictionary = {
	1: "Jan",
	2: "Feb",
	3: "Mar",
	4: "Apr",
	5: "May",
	6: "Jun",
	7: "Jul",
	8: "Aug",
	9: "Sep",
	10: "Oct",
	11: "Nov",
	12: "Dec"
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(_delta):
	var current_time = Time.get_datetime_dict_from_system()
	var hour = current_time["hour"]
	var minute = current_time["minute"]
	var month = current_time["month"]
	var day = current_time["day"]
	var year = current_time["year"]
	
	var am_pm
	
	if hour > 12:
		hour -= 12
		am_pm = "PM"
	else:
		am_pm = "AM"
		
	if hour == 0:
		hour = 12
	
	var formatted_time = "%d:%02d %s" % [hour, minute, am_pm]
	var formatted_date = "%s. %02d, %s" % [month_dictionary[month], day, year]
	time_label.text = formatted_time
	date_label.text = formatted_date
