extends CharacterBody3D
class_name Enemy

@export var health: float = 50

# Return True if	 the attack killed the enemy
func take_damage(amount: float) -> bool:
	health -= amount
	if health <= 0:
		die()
		return true # Dead
	return false # Alive
	
func die():
	queue_free()
