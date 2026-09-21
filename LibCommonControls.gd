@abstract
extends Object
## Defines some common [Control] objects
class_name LibCommonControls

## Defines a panel providing two clickable choice options[br]
## Values are returned through [member callback]
class PanelChoiceBinary extends Control:
	var callback : Callable = Callable();
	var panel : Panel;
	const PANEL_ANCHORS : PackedFloat32Array = [0.2,0.3,0.8,0.7];
	var vbox : VBoxContainer;
	var label : RichTextLabel;
	var hbox : HBoxContainer;
	var buttons : Array[Button];
	func _init(return_callable : Callable, label_text : StringName = &"Confirm") -> void:
		self.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED;
		self.set_anchors_preset(Control.PRESET_FULL_RECT);
		self.hide();
		
		panel = Panel.new();
		panel.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED;
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH;
		panel.grow_vertical = Control.GROW_DIRECTION_BOTH;
		self.add_child(panel);
		
		vbox = VBoxContainer.new();
		vbox.set_anchors_preset(PRESET_FULL_RECT);
		panel.add_child(vbox);
		
		label = RichTextLabel.new();
		label.text = label_text;
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL;
		label.size_flags_stretch_ratio = 7.0;
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER;
		label.grow_horizontal = Control.GROW_DIRECTION_BOTH;
		label.grow_vertical = Control.GROW_DIRECTION_BOTH;
		vbox.add_child(label);
		
		hbox = HBoxContainer.new();
		hbox.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED;
		hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL;
		hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH;
		hbox.grow_vertical = Control.GROW_DIRECTION_BEGIN;
		vbox.add_child(hbox);
		
		buttons.resize(2);
		for i : int in 2:
			buttons[i] = Button.new();
			buttons[i].size_flags_horizontal = Control.SIZE_EXPAND_FILL;
			#buttons[i].focus_mode = Control.FOCUS_NONE;
			hbox.add_child(buttons[i]);
			
		buttons[0].pressed.connect(decision.bind(false));
		buttons[1].pressed.connect(decision.bind(true));
		buttons[0].text = "Cancel";
		buttons[1].text = "Confirm";
		
		for side : int in 4:
			panel.set_anchor(side, PANEL_ANCHORS[side])
		callback = return_callable;
	
	func _ready() -> void:
		set_process_input(false);
		
	func toggleDisplay(nextState : bool) -> void:
		set_process_input(nextState);
		if nextState:
			get_viewport().gui_get_focus_owner().release_focus();
			
			focus_mode = Control.FOCUS_ALL;
			self.grab_focus();
			self.show();
		else:
			self.hide();
			
	## Called when a choice is made
	func decision(choice : bool) -> void:
		callback.call(choice);
		toggleDisplay(false);

	## Block tab events from passing through while prompt is open
	func _input(event: InputEvent) -> void:
		if event.is_action_pressed(&"ui_left"):
			buttons[0].grab_focus.call_deferred();
			accept_event();
			return;
		elif event.is_action_pressed(&"ui_right"):
			buttons[1].grab_focus.call_deferred();
			accept_event();
			return;
		elif event.is_action_pressed(&"ui_focus_next"):# || event.is_action_pressed(&"ui_focus_prev"):
			accept_event();
			return;
