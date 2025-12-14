extends CharacterBody3D
class_name Enemy

@export var health: float = 25


func _process(_delta):
	if health <= 0:
		die()
	
	
func take_damage(amount: float):
	health -= amount
	
func die():
	queue_free()
