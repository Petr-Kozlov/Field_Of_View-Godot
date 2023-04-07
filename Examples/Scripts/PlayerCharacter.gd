extends Node2D

export var _moveSpeed: float = 400.0;
export var _fieldOfViewPath : NodePath;

var _moveAxis: Vector2;

var _fieldOfView: FieldOfView2D;

func _ready():
	_fieldOfView = get_node(_fieldOfViewPath);


func _input(event):
	var x: float = Input.get_axis("Left_Move", "Right_Move");
	var y: float = Input.get_axis("Down_Move", "Up_Move");
	_moveAxis = Vector2(x, -y);

func _process(delta):
	_fieldOfView.SetFaceDirection(_moveAxis);
	global_position += _moveAxis.normalized() * _moveSpeed * delta;
