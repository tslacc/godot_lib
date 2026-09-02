extends Object
class_name RecipeTrees
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
## RecipeComponent defines the type and quantity of the given element.
class RecipeComponent extends Object:
	var type : ELEMENT_TYPE = ELEMENT_TYPE.E0;
	var quantity : float = 0.0;
	func equals(compare : RecipeComponent) -> bool:
		return (type == compare.type && quantity == compare.quantity);
## Each node contains one component, the next nodes (if any exist) and an output recipe if there is one.[br]
## A node containing a recipe is not necessarilly a leaf: you could have AB, ABC recipes.
class RecipeNode extends Object:
	var component : RecipeComponent = null;
	var next_nodes : Array[RecipeNode] = [];
	var output_recipe : RecipeTerminal = null;
	func equals(c : RecipeNode) -> bool:
		return (component.type == c.component.type && component.quantity == c.component.quantity);
	func search_equal_children(c : RecipeNode) -> RecipeNode:
		for child : RecipeNode in next_nodes:
			if child.equals(c): 
				return child;
		return null;
	func _init(c : RecipeComponent) -> void:
		component = c;
		return;

## The outcome of a given reaction.
class RecipeTerminal extends Object:
	var inputs : Array[RecipeComponent] = [];
	var outputs : Array[RecipeComponent] = [];
	var heat_lower : float = -1.0;
	var heat_upper : float = -1.0;
	var rate_factor : float = 1.0;
	var rate_factor_curvetype : int = 0;
	var rate_factor_heat : float = 0.0;
	var rate_factor_heat_curvetype : int = 0;

## TODO Change name?[br]
## Contains at most one root node for each existing element.[br]
## Trees are built in sorted order, e.g. A->B,C is forced.[br]
## Multiple A->B, B are possible so long as the B component has a different ratio. [br]
static var compiled_trees : Array[RecipeNode];

## Add a single recipe to [member compiled_trees][br]
## Inputs shold be sorted already.[br]
## Frees the unplaced recipe components.
static func add_recipe(root_node : RecipeNode) -> void:
	# Check if you can place a root node.
	if(compiled_trees[root_node.component.type]==null):
		compiled_trees[root_node.component.type] = root_node;
		return;
	var candidate_node : RecipeNode = root_node.next_nodes[0];
	var current_branch : RecipeNode = compiled_trees[root_node.component.type];
	# If for some reason current branch has no children...?
	if current_branch.next_nodes.size()==0:
		current_branch.next_nodes.push_back(candidate_node);
		return;
	# While there are still children to go through
	while(candidate_node.next_nodes.size()!=0):
		var tmp_node : RecipeNode = candidate_node.next_nodes[0];
		candidate_node.free();
		candidate_node = tmp_node;
		# Place the new node as a child of this node IFF this node has **no** equivalent children.
		# If there is an equivalent child then move to the next while loop.
		# If this branch has no children, then search_equal_children will return null.
		for child_node : RecipeNode in current_branch.next_nodes:
			var tmp : RecipeNode = current_branch.search_equal_children(candidate_node);
			if tmp == null:
				current_branch.next_nodes.push_back(candidate_node);
				current_branch.next_nodes.sort_custom(sort_nodes);
				return;
			else:
				current_branch = tmp;
	# If the current node is the terminal node, then it must be placed immediately.
	assert(candidate_node.output_recipe!=null);
	# Assert that no perfectly matching recipe exists
	assert(current_branch.search_equal_children(candidate_node)==null);
	#Place the new node
	current_branch.next_nodes.push_back(candidate_node);
	return;

## Converts input into a recipe node sequence.
static func components_to_nodes(input : Array[RecipeComponent], result_recipe : RecipeTerminal) -> RecipeNode:
	# Do not trust: sort everything.
	input = standardizeArrayComponent(input);
	result_recipe.inputs = standardizeArrayComponent(result_recipe.inputs);
	result_recipe.outputs = standardizeArrayComponent(result_recipe.outputs);
	if input.size() == 0:
		push_error("Attempted to create recipe from empty list");
		return null;
	var result : RecipeNode = RecipeNode.new(input[0]);
	var idx : int = 1;
	var current_node : RecipeNode = result;
	while(idx < input.size()):
		current_node.next_nodes.push_back(RecipeNode.new(input[idx]));
		current_node = current_node.next_nodes.back();
		idx+=1;
	current_node.output_recipe = result_recipe;
	return result;

## Subsort function for an array of [class RecipeNode] [br]
## Wrapper for [method sort_components]
static func sort_nodes(arg1 : RecipeNode, arg2 : RecipeNode)->bool:
	return sort_components(arg1.component, arg2.component);
## Subsort function for an array of [class RecipeComponent]
static func sort_components(arg1 : RecipeComponent, arg2 : RecipeComponent) -> bool:
	return arg1.type < arg2.type;
	
## Given the very first node of a recipe, return a SORTED linear recipe where the quantities have been adjusted such that the first element has a ratio of 1.0. [br]
## Mutates the array.
static func standardizeArrayComponent(components : Array[RecipeComponent]) -> Array[RecipeComponent]:
	# Sort the array
	components.sort_custom(sort_components);
	# Remove duplicates
	for idx : int in components.size()-1:
		if components[idx+1].type == components[idx].type:
			push_error("Error building recipe: contained duplicate component");
			return [];
	var scale_factor : float = 1.0;
	assert(components[0].quantity!=0);
	scale_factor = 1.0/components[0].quantity;
	for idx : int in components.size():
		components[idx].quantity *= scale_factor;
	return components;

## Static initializer enforces compiled trees to have n trees.
static func _static_init() -> void:
	compiled_trees.resize(ELEMENT_TYPE.keys().size());
	return;
	
## Returns an array of valid [class RecipeComponent][br]
## Assume that every entry in compareArray is a nonzero component.
static func get_valid_recipes(compareArray : Array[RecipeComponent]) -> Array[RecipeTerminal]:
	var result : Array[RecipeTerminal] = [];
	var idx : int= 0;
	##TODO work
	# We can assert that **both** the child nodes and compareArray components are sorted, so we can cheat
	var dfs_mutex : Mutex = Mutex.new();
	while idx < compareArray.size():
		# If there is a possible root in the source array, traverse the tree afterwards
		assert(compareArray[idx].quantity!=0);
		assert(compareArray[idx].type<ELEMENT_TYPE.keys().size());
		if(compareArray[idx].quantity==0):
			idx+=1;
			continue;
		if(compiled_trees[compareArray[idx].type]!=null):
			print("Begin DFS with initial type %d"%[compareArray[idx].type]);
			dfs_tree(dfs_mutex, compiled_trees[compareArray[idx].type], compareArray, result, idx);
		idx+=1;
	return result;

static func dfs_mutex_insert(mutex : Mutex, next_recipe : RecipeTerminal, storage : Array[RecipeTerminal]) -> void:
	mutex.lock();
	storage.push_back(next_recipe);
	mutex.unlock();
	return;

static func dfs_tree(mutex : Mutex, tree : RecipeNode, compareArray : Array[RecipeComponent], storage : Array[RecipeTerminal], idx : int = 0) -> void:
	if tree.next_nodes.size() == 0:
		#assert(tree.output_recipe!=null);
		var final_type : int = tree.component.type;
		print("Reached terminal node w final type %d"%[tree.component.type]);
		if(tree.output_recipe!=null):
			dfs_mutex_insert(mutex, tree.output_recipe, storage);
	else:
		var sub_idx : int = 0;
		while idx < compareArray.size() && sub_idx < tree.next_nodes.size():
			# if compareArray has a matching component type with a child node, do subdfs.
			if compareArray[idx].type == tree.next_nodes[sub_idx].component.type:
				dfs_tree(mutex, tree.next_nodes[sub_idx], compareArray, storage, idx);
				sub_idx+=1;
			else:
				if compareArray[idx].type<tree.next_nodes[sub_idx].component.type:
					idx+=1;
				else:
					sub_idx+=1;
	return;
	
