class_name FieldOfView2D 
extends Area2D

export var _radius: float = 3.0;
export var _angleView: int = 90;
export var _refreshTime: float = 0.02;
export var _meshResolution: float = 0.5;
export var _edgeResolveIterations: int = 4;
export var _edgeDistanceThreshold: float = 0.5;
export(int, LAYERS_2D_PHYSICS) var _obstacleLayer: int;

export var _collision2DPath: NodePath;
export var _meshInstance2DPath: NodePath;

export var _normalColor : Color;
export var _detectColor : Color;

var _faceDirection: Vector2 = Vector2(1, 0);

var _collisionPolygon: CollisionPolygon2D;
var _meshInstance: MeshInstance2D;

var _refreshTimer: float = 0;

var _viewTargets: int = 0;

func _ready():
	_collisionPolygon = get_node(_collision2DPath);
	_collisionPolygon.build_mode = CollisionPolygon2D.BUILD_SOLIDS
	_meshInstance = get_node(_meshInstance2DPath);



func _process(delta):
	_refreshTimer += delta;
	if(_refreshTimer >= _refreshTime):
		CheckViewTargets();
		_refreshTimer = 0.0;


	
func SetFaceDirection(direction : Vector2):
	if (direction != Vector2.ZERO):
		_faceDirection = direction;

		
		
func CheckViewTargets():

	var stepCount: int = RoundToInt(_angleView * _meshResolution);
	var stepAngleSize: float = _angleView / stepCount;
	var points: PoolVector2Array = PoolVector2Array();
	
	var faceAngle: int =  RoundToInt(rad2deg(_faceDirection.angle()));
	var oldViewCast: ViewCastInfo;
	
	var center: Vector2 = Vector2.ZERO;
	points.append(center);
	
	for index in range(0, stepCount + 1):
		var angle: float = faceAngle - _angleView / 2 + stepAngleSize * index;
		var newViewCast: ViewCastInfo = ViewCast(angle);

		if (index > 0):
			var edgeDistanceThresholdExceeded: bool = abs(oldViewCast.Distance - newViewCast.Distance) > _edgeDistanceThreshold;
			if (oldViewCast.IsHit != newViewCast.IsHit || (oldViewCast.IsHit && newViewCast.IsHit && edgeDistanceThresholdExceeded)):
				var edge: EdgeInfo = FindEdge(oldViewCast, newViewCast);
				
				if (edge.PointA != Vector2.ZERO):
					points.append(edge.PointA - global_position);

				if (edge.PointB != Vector2.ZERO):
					points.append(edge.PointB - global_position);
		
		points.append(newViewCast.Point - global_position);
		oldViewCast = newViewCast;
		
	_collisionPolygon.polygon = points;	
	
	DrawMesh(points);
	RefreshCoolor();
	
	

func RoundToInt(value) -> int:
	return int(round(value));
	
	

func ViewCast(angle : float) -> ViewCastInfo:
	var direction: Vector2 = Vector2(cos(deg2rad(angle)), sin(deg2rad(angle)));

	var from: Vector2 = global_position;
	var to: Vector2 = global_position + direction * _radius;
			
	var rayResult: Dictionary = get_world_2d().direct_space_state.intersect_ray(from, to, [], _obstacleLayer, true, true);
	
	if (rayResult.empty() == false && rayResult["collider"] != null):
		var distance: float = from.distance_to(rayResult["position"])
		return ViewCastInfo.new(true, rayResult["position"], distance, angle);
			
	return ViewCastInfo.new(false, to, _radius, angle);
	
	

func FindEdge(minViewCast : ViewCastInfo, maxViewCast : ViewCastInfo) -> EdgeInfo:
	var minAngle: float = minViewCast.Angle;
	var maxAngle: float = maxViewCast.Angle;
	
	var minPoint: Vector2 = minViewCast.Point;
	var maxPoint: Vector2 = maxViewCast.Point;
	
	for index in range (0, _edgeResolveIterations):
		var angle: float = (minAngle + maxAngle) / 2;
		var newViewCast: ViewCastInfo = ViewCast(angle);
		var edgeDistanceThresholdExceeded: bool = abs(minViewCast.Distance - newViewCast.Distance) > _edgeDistanceThreshold;

		if (newViewCast.IsHit == minViewCast.IsHit && edgeDistanceThresholdExceeded == false):
			minAngle = angle;
			minPoint = newViewCast.Point;
		else:
			maxAngle = angle;
			maxPoint = newViewCast.Point;
			
	return EdgeInfo.new(minPoint, maxPoint);



func DrawMesh(points: Array):

	var vertexCount: int = points.size() + 1;
	
	var vertices: PoolVector2Array = PoolVector2Array();
	vertices.resize(vertexCount);
	var triangles: PoolIntArray = PoolIntArray();
	triangles.resize((vertexCount - 2) * 3);
	
	#vertices[0] = center;	
	for index in range(0, vertexCount - 1):
		vertices[index + 1] = points[index];
		
		if (index < vertexCount - 2):
			triangles[index * 3] = 0;
			triangles[index * 3 + 1] = index + 1;
			triangles[index * 3 + 2] =  index + 2;

	var arrayData: Array;
	arrayData.resize(ArrayMesh.ARRAY_MAX);
	arrayData[ArrayMesh.ARRAY_VERTEX] = vertices;
	arrayData[ArrayMesh.ARRAY_INDEX] = triangles;
	
	var arrayMesh : ArrayMesh = ArrayMesh.new();
	arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrayData);
	
	_meshInstance.mesh = arrayMesh;



func RefreshCoolor():	
	if((_viewTargets > 0)):
		_meshInstance.modulate = _detectColor;
	else:
		_meshInstance.modulate = _normalColor;


func _on_FieldOfView2D_area_entered(area):
	_viewTargets += 1;


func _on_FieldOfView2D_area_exited(area):
	_viewTargets -= 1;
