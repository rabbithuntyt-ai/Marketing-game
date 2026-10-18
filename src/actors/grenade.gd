class_name Grenade
extends RigidBody3D
## Frag grenade: bounces, beeps, explodes with falloff damage to everyone nearby.

var mission: Node
var fuse := 1.9
var from_enemy := false
var _led: MeshInstance3D

func _ready() -> void:
	collision_layer = 0; collision_mask = Humanoid.LAYER_WORLD
	mass = 0.4; continuous_cd = true
	var pm := PhysicsMaterial.new(); pm.bounce = 0.35; pm.friction = 0.8; physics_material_override = pm
	var cs := CollisionShape3D.new(); var sh := SphereShape3D.new(); sh.radius = 0.07; cs.shape = sh; add_child(cs)
	var mi := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.07; sm.height = 0.14; mi.mesh = sm; mi.material_override = Mats.flat(Color(0.22, 0.27, 0.16), 0.6, 0.3); add_child(mi)
	_led = MeshInstance3D.new(); var lm := SphereMesh.new(); lm.radius = 0.02; lm.height = 0.04; _led.mesh = lm; _led.material_override = Mats.glow(Color(1, 0.15, 0.1), 6.0); _led.position.y = 0.07; add_child(_led)
	contact_monitor = true; max_contacts_reported = 2
	body_entered.connect(func(_b): if linear_velocity.length() > 2.0: Audio.play3d("brass", global_position, -8.0, 0.2, 3.0))

func _process(dt: float) -> void:
	fuse -= dt
	_led.visible = sin(fuse * (30.0 - fuse * 10.0)) > 0.0
	if fuse <= 0.0:
		explode(); queue_free()

func explode() -> void:
	var p := global_position
	Fx.explosion(p)
	if mission: mission.blast(p, 5.5, 260.0, from_enemy)
