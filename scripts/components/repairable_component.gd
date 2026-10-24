class_name RepairableComponent
extends Node3D
## One separately addressable mechanical part on a vehicle (filter, drain plug, battery...).
## Holds identity, the tool it needs, condition, and install state. Visuals are child meshes;
## the tappable collider is a child Interactable. Job rules stay in gameplay scripts — this
## node only describes the part and shows its state.

enum State { INSTALLED, REMOVED, OPEN }

@export var component_id: String = ""
@export var display_name: String = ""
## Tool id from main.gd TOOLS that services this part ("" = not serviceable yet).
@export var required_tool: String = ""
## Which camera view the part is reached from: "under", "engine" or "bay".
@export var access_view: String = "engine"
@export_range(0.0, 1.0) var condition: float = 1.0
@export var removable: bool = false
## False when the part is baked into a combined mesh and cannot really be removed.
@export var separate_mesh: bool = true
@export var state: State = State.INSTALLED

signal state_changed(component: RepairableComponent)


func set_state(new_state: State) -> void:
	state = new_state
	visible = new_state != State.REMOVED
	state_changed.emit(self)


func describe() -> Dictionary:
	return {
		"id": component_id,
		"name": display_name,
		"tool": required_tool,
		"view": access_view,
		"condition": condition,
		"state": State.keys()[state],
		"separate_mesh": separate_mesh,
	}
