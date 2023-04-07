class_name ViewCastInfo

var IsHit : bool;
var Point : Vector2;
var Distance: float;
var Angle: float;

func _init(isHit, point, distance, angle):
	IsHit = isHit;
	Point = point;
	Distance = distance;
	Angle = angle;
