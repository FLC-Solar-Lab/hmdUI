extends Grabbable


func _ready() -> void:
	super._ready()
	
	## set the collision shape to that of the shape of the dynamically generated UI
	var collision = find_child("CollisionShape3D")
	var ui = find_child("hmdUI")
	sync_collision_shape(ui, collision)
		

func get_total_ui_aabb(start_node: Node3D) -> AABB:
	var total_aabb := AABB()
	var has_visuals := false

	# We need to check all children recursively
	for child in start_node.get_children(true):
		if child is VisualInstance3D:
			# get_aabb() returns the local bounding box of the mesh or sprite
			var local_aabb: AABB = child.get_aabb()
			
			# Transform the local AABB into the start_node's coordinate space
			var global_aabb = child.transform * local_aabb
			
			if not has_visuals:
				total_aabb = global_aabb
				has_visuals = true
			else:
				total_aabb = total_aabb.merge(global_aabb)
		
		# If the child has its own children, check them too
		if child.get_child_count() > 0:
			var child_aabb = get_total_ui_aabb(child)
			# Transform child's combined AABB into current space
			if not has_visuals:
				total_aabb = child.transform * child_aabb
				has_visuals = true
			else:
				total_aabb = total_aabb.merge(child.transform * child_aabb)
				
	return total_aabb
	
	
func sync_collision_shape(ui_node: Node3D, col_node: CollisionShape3D):	
	var ui_bounds = get_total_ui_aabb(ui_node)
	
	if col_node and col_node.shape is BoxShape3D:
		# Use the bounds directly (already scaled)
		col_node.shape.size = Vector3(ui_bounds.size.x, ui_bounds.size.y, 0.001)
		
		# push grabbales behind UI buttons and such
		var z_recess = Vector3(0, 0, -0.01)
		
		# Set position relative to the pivot without double-scaling
		col_node.position = ui_node.position + ui_bounds.get_center() + z_recess
			
