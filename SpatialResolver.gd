extends Node3D
class_name SpatialResolver

@export var ray_length: float = 50.0
@export var collision_mask: int = 1

var _last_hit: Dictionary = {}  # sender_id -> Dictionary

func raycast_widget(sender_id: int, pos: Vector3, dir: Vector3) -> UIWidget:
	return _raycast_widget(sender_id, pos, dir)

func get_last_hit(sender_id: int) -> Dictionary:
	return _last_hit.get(sender_id, {})

func _raycast_widget(sender_id: int, pos: Vector3, dir: Vector3) -> UIWidget:
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.new()
	ray.from = pos
	ray.to = pos + dir.normalized() * ray_length
	ray.collision_mask = collision_mask
	ray.hit_from_inside = true
	ray.hit_back_faces = true

	var hit = space.intersect_ray(ray)

	if not hit:
		_last_hit.erase(sender_id)
		return null

	_last_hit[sender_id] = {
		"point": hit.position,
		"normal": hit.normal,
		"distance": pos.distance_to(hit.position),
		"collider": hit.collider
	}

	var c = hit.collider
	if c is UIWidget:
		return c
	if c is Node:
		var p: Node = c
		while p != null:
			if p is UIWidget:
				return p
			p = p.get_parent()

	return null
