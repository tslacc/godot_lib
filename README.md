Collection of some potentially useful schemes.
RecipeTrees is a tree-based implementation of a chemically-inspired reaction system. Given a defined list of n "elements", this RecipeTree system enforces the existence of n (ideally n-1) trees.
 Each tree represents a combination of "elements", and a valid root-to-leaf pathing represents one reaction.
 Each tree has strict ordering rules. The root must be the smallest element by enum type, and each subsequent child node must also be sorted left-to-right among its siblings.
 
