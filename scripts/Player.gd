extends KinematicBody2D

const Item := preload("res://scripts/Item.gd")
const ItemScene := preload("res://entities/Item.tscn")
const PixelCamera := preload("res://scripts/PixelCamera.gd")
const PixelCameraScene := preload("res://entities/PixelCamera.tscn")
const Door := preload("res://scripts/Door.gd")

export var gravity := 500.0
export var walk_speed := 150.0
export var jump_speed := 200.0

const _SNAP_DISTANCE := 2.0
const _MAX_SLIDES := 5
const _MAX_SLOPE_ANGLE := 0.25 * PI

var _velocity := Vector2.ZERO

onready var _area := $Area2D
onready var _hand := $Hand
var _held_item : Item = null
var _held_item_parent : Node2D = null

var _map_side := "right"
var _facing_direction := ""

var player2_scene : String = "res://rooms/Test2.tscn"
#var _briefcase_timer := Timer.new()


func _ready() -> void:
	var camera : PixelCamera = PixelCameraScene.instance()
	self.add_child(camera)
	camera.current = true
	

func _physics_process(delta : float) -> void:
	if !.is_on_floor():
		self._velocity.y += self.gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			self._velocity.y = -self.jump_speed

	var move_dir := 0
	if Input.is_action_pressed("walk_left"):
		move_dir -= 1
		_facing_direction = "left"
	if Input.is_action_pressed("walk_right"):
		move_dir += 1
		_facing_direction = "right"
	self._velocity.x = move_dir * self.walk_speed

	var snap := self._SNAP_DISTANCE * Vector2.DOWN
	self._velocity = .move_and_slide_with_snap(self._velocity, snap, Vector2.UP, false, self._MAX_SLIDES, self._MAX_SLOPE_ANGLE, true);

func _process(_delta : float) -> void:
	if Input.is_action_just_pressed("interact") and Input.is_action_pressed("duck"):
		if _held_item == null: #picking up an item
			var collision_areas : Array = _area.get_overlapping_areas()
			var indices = collision_indices(collision_areas)
			if indices.x >= 0:
				var item = collision_areas[indices.x].get_parent()
				if item.can_pick_up:
					_pick_up_item(item)
		else: #dropping an item
			_drop_item()
	elif Input.is_action_just_pressed("interact"):
		if _held_item == null: #enter door
			var collision_areas : Array = _area.get_overlapping_areas()
			var indices = collision_indices(collision_areas)
			if indices.y >= 0:
				_enter_door(collision_areas[indices.y].get_parent())
		else: #use item
			_held_item.use_item(_facing_direction)
			_drop_item()

#think of a better way to do this prolly
func collision_indices(collision_areas) -> Vector2:
	var output = Vector2(-1, -1)
	for i in collision_areas.size():
		var collision : Node2D = collision_areas[i].get_parent()
		if collision is Item:
			output.x = i
		elif collision is Door:
			output.y = i
		if output.x >= 0 and output.y >= 0:
			break
	return output

func _pick_up_item(item) -> void:
	_held_item = item
	_held_item.held = true
	_held_item_parent = item.get_parent()
	item.get_parent().remove_child(_held_item)
	_hand.add_child(_held_item)
	_held_item.position = Vector2.ZERO
	_held_item._velocity = Vector2.ZERO
	if _held_item.type == "briefcase":
		if GameController.stage == 2:
			GameController.game_over()
		#else:
		#	_briefcase_timer.start(rand_range(10, 30))

func _drop_item() -> void:
	if _held_item.type == "briefcase":
		for i in rand_range(1, 3):
			var paper = ItemScene.instance()
			paper.type = "paper"
			paper.gravity = 200
			paper._velocity.y = -rand_range(150, 250)
			if self._facing_direction == "right":
				paper._velocity.x = rand_range(50, 100)
			elif self._facing_direction == "left":
				paper._velocity.x = -rand_range(50, 100)
			_held_item_parent.add_child(paper)
			paper.position = _held_item.global_position
	var held_item_pos := _held_item.global_position
	_held_item.held = false
	_hand.remove_child(_held_item)
	_held_item_parent.add_child(_held_item)
	_held_item.global_position = held_item_pos
	_held_item = null
	_held_item_parent = null
	

func _enter_door(door):
	GameController.change_room(door)


func switch_stage():
	if _held_item.type != null:
		_drop_item()
	if _map_side == "right":
		_map_side = "left"
	elif _map_side == "left":
		_map_side = "right"


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		print("AHHHHH")
