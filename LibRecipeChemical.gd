extends Object
## Defines an array of MinHeaps representing reactions.[br]
class_name RecipeChemical

## An array of MinHeap compiled trees.[br]
## The index of the tree corresponds to the root of the tree for fast initial lookup.[br]
## Each root [CNode] must have a corresponding quantity of 1.0 units. Every subsequent unit is defined with respect to that 1.0 quantity.[br]
## The children of each [CNode] must have a [enum ELEMENT_TYPE] [b]greater[/b] than its parent.[br]
## Multiple output recipes may be located at any node.[br]
## We avoid the need for sifting/reordering by preconditioning our input to be fully sorted before entry.[br]
static var compiled_trees : Array[CNode];

## Types of elements.
enum ELEMENT_TYPE{
	E0,
	E1,
	E2,
	E3,
	E4,
	E5,
	E6,
	E7,
	E8,
	E9,
	E10,
	E11,
	E12,
	E13
}
## Each node contains one component, the next nodes (if any exist) and an output recipe if there is one.[br]
## A node containing a recipe is not necessarilly a leaf: you could have AB, ABC recipes.
class CNode extends Object:
	var type : ELEMENT_TYPE = 0 as ELEMENT_TYPE;
	var quantity : float = 0.0;
	var next_nodes : Array[CNode] = [];
	var output_recipes : Array[CRecipe] = [];
	func equals(c : CNode) -> bool:
		return (type == c.type && quantity == c.quantity);
	func search_equal_children(c : CNode) -> CNode:
		for child : CNode in next_nodes:
			if child.equals(c):
				return child;
		return null;
	func _init(new_type : ELEMENT_TYPE, new_quantity : float) -> void:
		type = new_type;
		quantity = new_quantity;
		return;

## The outcome of a given reaction.
class CRecipe extends Object:
	var input_types : PackedInt32Array = [];
	var input_quantities : PackedFloat32Array = [];
	var output_types : PackedInt32Array = [];
	var output_quantities : PackedFloat32Array = [];
	var heat_lower : float = -1.0;
	var heat_upper : float = -1.0;
	var rate_factor : float = 1.0;
	var rate_factor_curvetype : int = 0;
	var rate_factor_heat : float = 0.0;
	var rate_factor_heat_curvetype : int = 0;

## Converts an array of [CRecipe] to a PackedByteArray for saving to file.
static func array_recipe_to_bytes(arr : Array[CRecipe]) -> PackedByteArray:
	# Degenerate case
	var buffer : LIB_BUFFER.BUFFER_RW = LIB_BUFFER.BUFFER_RW.new();
	buffer.encode_string(GlobalControl.BUILD_STRING);
	buffer.encode_byte(arr.size());
	for recipe : CRecipe in arr:
		#Encode input values
		assert(recipe.input_types.size() == recipe.input_quantities.size());
		buffer.encode_byte(recipe.input_types.size());
		for idx : int in recipe.input_types.size():
			## TODO Change this if more than 255 elements are planned
			buffer.encode_byte(recipe.input_types[idx]);
		for idx : int in recipe.input_types.size():
			buffer.encode_float(recipe.input_quantities[idx]);
		
		# Encode output values
		assert(recipe.output_types.size() == recipe.output_quantities.size());
		buffer.encode_byte(recipe.output_types.size());
		for idx : int in recipe.input_types.size():
			## TODO Change this if more than 255 elements are planned
			buffer.encode_byte(recipe.output_types[idx]);
		for idx : int in recipe.input_types.size():
			buffer.encode_float(recipe.output_quantities[idx]);
	buffer.buf.resize(buffer.offset);
	var result : PackedByteArray = buffer.buf.duplicate();
	buffer.free();
	return result;
		
## Add a [CRecipe] to [member compiled_trees].
static func add_terminal_recipe(recipe : CRecipe) -> void:
	var root_node : CNode = components_to_nodes(recipe);
	if(compiled_trees[root_node.type]==null):
		compiled_trees[root_node.type] = root_node;
		return;
	var candidate_node : CNode = root_node.next_nodes[0];
	var current_branch : CNode = compiled_trees[root_node.type];
	# If for some reason current root has no children...?
	if current_branch.next_nodes.size()==0:
		current_branch.next_nodes.push_back(candidate_node);
		return;
	# Walk the candidate node path
	while(candidate_node.next_nodes.size()!=0):
		var tmp_node : CNode = candidate_node.next_nodes[0];
		candidate_node.free();
		candidate_node = tmp_node;
		# Place the new node as a child of this node IFF this node has **no** equivalent children.
		# If there is an equivalent child then move to the next while loop.
		# If this branch has no children, then search_equal_children will return null.
		for child_node : CNode in current_branch.next_nodes:
			var tmp : CNode = current_branch.search_equal_children(candidate_node);
			# If this branch has no matching children for the candidate node, add this node as a new child.
			if tmp == null:
				current_branch.next_nodes.push_back(candidate_node);
				current_branch.next_nodes.sort_custom(sort_nodes);
				return;
			else:
				# Continue to traverse down the tree
				current_branch = tmp;
	# If the current node is the terminal node, then it must be placed immediately.
	assert(candidate_node.output_recipes.size()!=0);
	# Assert that no perfectly matching recipe exists
	assert(current_branch.search_equal_children(candidate_node)==null);
	#Place the new recipe as a child of the current branch.
	current_branch.output_recipes.push_back(candidate_node.output_recipes[0]);
	candidate_node.free();
	return;

## Converts input into a recipe node sequence; inputs must be sorted.
static func components_to_nodes(recipe_base : CRecipe) -> CNode:
	if recipe_base.input_quantities.size() == 0:
		push_error("Attempted to create recipe from empty list");
		return null;
	var result : CNode = CNode.new(recipe_base.input_types[0], recipe_base.input_quantities[0]);
	var idx : int = 1;
	var current_node : CNode = result;
	while(idx < recipe_base.input_types.size()):
		current_node.next_nodes.push_back(CNode.new(recipe_base.input_types[idx], recipe_base.input_quantities[idx]));
		current_node = current_node.next_nodes.back();
		idx+=1;
	current_node.output_recipes.push_back(recipe_base);
	return result;

## Subsort function for an array of [class CNode] [br]
## Wrapper for [method sort_components]
static func sort_nodes(arg1 : CNode, arg2 : CNode)->bool:
	if (arg1.type < arg2.type):
		return true;
	elif (arg1.type > arg2.type):
		return false;
	if (arg1.quantity < arg2.quantity):
		return true;
	elif (arg1.quantity > arg2.quantity):
		return false;
	return false;

## Mutate [param recipe] to have sorted input and output types.[br]
## Normalizes only input quantities.[br]
## Input quantities are always non-negative.[br]
## Output quantities can be blank, for recipes that simply destroy material.
static func standardizeCRecipe(recipe : CRecipe) -> void:
	assert(recipe.input_quantities.size()!=0);
	# Pair-sort the subarray while asserting that there are no duplicates
	# Force scale the subarrays to the first elements.
	var tracking_array : PackedInt32Array = LIB_SORT.quicksort_PackedInt32_preserve_order(recipe.input_types);
	LIB_SORT.cyclesort_PackedFloat_fixedorder(recipe.input_quantities, tracking_array);
	var scale_factor : float = 1.0/recipe.input_quantities[0];
	for i : int in recipe.input_quantities.size():
		recipe.input_quantities[i]*=scale_factor;
	return;

## Static initializer enforces compiled trees to have n trees.[br]
## Read cache and build trees.
static func _static_init() -> void:
	compiled_trees.resize(ELEMENT_TYPE.keys().size());
	return;

## Returns an array of valid [class RecipeComponent][br]
## [param compareArray] is a list of every type to compare with.
static func get_valid_recipes(compareArray : PackedInt32Array) -> Array[CRecipe]:
	var result : Array[CRecipe] = [];
	var idx : int = 0;
	var dfs_mutex : Mutex = Mutex.new();
	while idx < compareArray.size():
		# If there is a possible root in the source array, traverse the tree afterwards
		assert(compareArray[idx]!=0);
		assert(compareArray[idx]<ELEMENT_TYPE.keys().size());
		if(compiled_trees[compareArray[idx]]!=null):
			dfs_tree(dfs_mutex, compiled_trees[compareArray[idx]], compareArray, result, idx);
		idx+=1;
	return result;

##Support function for mass parallelization via mutex.
static func dfs_mutex_insert(mutex : Mutex, next_recipe : CRecipe, storage : Array[CRecipe]) -> void:
	mutex.lock();
	storage.push_back(next_recipe);
	mutex.unlock();
	return;

##Subcall for parsing the dfs tree and storing any valid recipes into a storage array.
static func dfs_tree(mutex : Mutex, tree : CNode, compareArray : PackedInt32Array, storage : Array[CRecipe], idx : int = 0) -> void:
	if(tree.output_recipes.size()!=0):
		for tmp_idx : int in tree.output_recipes.size():
			dfs_mutex_insert(mutex, tree.output_recipes[tmp_idx], storage);
	if tree.next_nodes.size() == 0:
		return;
	else:
		var sub_idx : int = 0;
		while idx < compareArray.size() && sub_idx < tree.next_nodes.size():
			# if compareArray has a matching component type with a child node, do subdfs.
			if compareArray[idx] == tree.next_nodes[sub_idx].type:
				dfs_tree(mutex, tree.next_nodes[sub_idx], compareArray, storage, idx);
				sub_idx+=1;
			else:
				if compareArray[idx]<tree.next_nodes[sub_idx].type:
					idx+=1;
				else:
					sub_idx+=1;
	return;
