extends Node3D

### Base Class
# Attach or extend to any object that can be moved by each clients' ray.
# Attached node MUST be a StaticBody3D if using defult Self in static_bodies.
#	- attached a collision object to StaticBody3D
class_name Grabbable


@export var bumper_is_pressed_path: Node
@export var bumper_is_released_path: Node
# optionally add more grabbables, defaults to the node script is attached to
@export var grabbables: = [self]   # MUST BE StaticBody3D
# if enabled: object with face cleint's ray when it is grabbed, allowing for rotation
@export var allow_roations = true


# ID of the client that currently owns the object
var possession_id = 0  # 0 means no user is grabbing

# when grabbing, keep track of grab positions of vectors
var dist_from_pos = 0
var obs_offset = 0


func _ready() -> void:
	bumper_is_pressed_path.position_updated.connect(_grab_object)
	bumper_is_released_path.position_set.connect(_release_object)
	set_process(false)  # not using
	
	
func _grab_object(pos: Vector3, dir: Vector3, sender_id: int):
	# another ID is already grabbing the object
	if possession_id != 0:
		_move_obstacle(pos, dir)
		return
	
	# check if sender has collision with object
	if !check_collision(pos, dir):
		return

	### client has sucessfully grabbed an obstacle ###
	print_debug("%d has grabbed an obstacle." % sender_id)
	possession_id = sender_id  # lock object to sender
	
	
func _release_object(sender_id: int):
	if sender_id == possession_id:
		possession_id = 0
		print_debug("%d has released an obstacle." % sender_id)

	
func _move_obstacle(pos: Vector3, dir: Vector3):
	# get first visible obstacle
	var cur_obs: Node3D = null
	for obs in grabbables:
		if obs.visible:
			cur_obs = obs
			break

	# movement/grabbing is turned off if node is not visible
	if cur_obs == null:
		return 
		
	# update the objects global position
	cur_obs.global_position = pos + (dir * dist_from_pos) - obs_offset
	
	if allow_roations:
		# set the roation to look toward the user's ray
		cur_obs.look_at(cur_obs.global_position + dir)
	
	
func check_collision(from_pos: Vector3, direction: Vector3, distance: float=50) -> bool:
	"""Checks collision; if there is a collision, also updates dis_from_pos"""
	var space_state = get_world_3d().direct_space_state
	
	# define vector and queery
	var ray_start = from_pos
	var ray_end = from_pos + (direction * distance)
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	
	# fire ray
	var result = space_state.intersect_ray(query)
	if not result:
		return false   # no collision at all
	if result.collider not in grabbables:
		return false   # no collision with object
		
	# get the distance from the cleints ray source and object center
	dist_from_pos = abs(from_pos.distance_to(result.position))
	obs_offset = result.position - result.collider.global_position
	return true
