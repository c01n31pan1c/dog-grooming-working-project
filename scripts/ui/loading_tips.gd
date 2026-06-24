## LoadingTips — Provides random tips for loading screens.
## Mixes breed facts, grooming technique tips, and gameplay hints.
## Tips don't repeat within a session until all have been shown.
class_name LoadingTips
extends RefCounted

const TIPS: Array[String] = [
	# Breed facts
	"Did you know? Poodles don't shed — their hair grows continuously like human hair!",
	"Golden Retrievers have a water-repellent double coat that should NEVER be shaved — it protects them from heat and cold.",
	"The Schnauzer's iconic beard originally protected their muzzle from rat bites — they were bred as ratters!",
	"Irish Terriers were the first breed used as messenger dogs in World War I.",
	"Each Irish Terrier hair is darkest at the tip and fades to wheaten at the root — freshly stripped coats look darker.",
	"Poodles were originally water retrievers — their fancy clips protected joints and organs during cold water work.",
	"Miniature Schnauzers come in four AKC-recognized colors: salt and pepper, black, black and silver, and white.",
	"The Golden Retriever's feathering — the longer hair on legs, chest, and tail — should be trimmed with thinning shears, never clipped.",
	"A Standard Poodle Continental Clip can take a professional groomer 2-4 hours to complete.",
	"Irish Terriers are sometimes called 'Red Devils' for their fiery temperament and striking coat color.",

	# Grooming technique tips
	"Tip: Always brush before clipping to remove tangles — clipping over mats is painful for the dog and dulls your blades.",
	"Tip: A #10 blade cuts hair to about 1/16 inch — it's the standard choice for Poodle face, feet, and tail shaving.",
	"Tip: Hand-stripping pulls dead coat by hand to preserve wiry texture — clipping a wire coat makes it softer over time.",
	"Tip: Brush a Golden Retriever BEFORE bathing — water turns tangles into rock-hard mats that must be cut out.",
	"Tip: A Schnauzer's eyebrows are cut diagonally — short at the inner corner, long at the outer — to create their stern expression.",
	"Tip: An undercoat rake is essential for double-coated breeds — it removes dead undercoat without cutting the topcoat.",
	"Tip: When hand-stripping, pull hair in the direction it grows — never against the grain.",
	"Tip: A high-velocity dryer blows out more loose undercoat than an hour of brushing — essential for deshedding.",
	"Tip: Clipper blades get hot during use — touch-test them regularly to avoid burning the dog's skin.",
	"Tip: Thinning shears remove bulk without leaving visible cut lines — perfect for blending and natural-looking trims.",

	# Gameplay hints
	"Hint: Pay attention to the grooming guide overlay — it shows exactly which tool and guard size each zone needs.",
	"Hint: Complete zones in the suggested order for the best time bonus.",
	"Hint: Spending coins to reveal a judge's preferences before a competition can give you a significant edge.",
	"Hint: Each breed has unique grooming facts — check the Breed-pedia to learn them all!",
	"Hint: Higher difficulty breeds earn more competition points — risk vs reward!",
	"Hint: Grooming accuracy matters more than speed — a perfect groom beats a fast one every time.",
	"Hint: Unlock new breeds by advancing through competition tiers and winning shows.",
	"Hint: The color-coded grooming guide uses warmer colors for shorter cuts — red means very close, blue means leave it long.",
]

## Indices of tips already shown this session.
static var _shown_indices: Array[int] = []


## Returns a random tip that hasn't been shown this session.
## Resets the pool when all tips have been displayed.
static func get_random_tip() -> String:
	# Build available pool
	var available: Array[int] = []
	for i in range(TIPS.size()):
		if i not in _shown_indices:
			available.append(i)

	# Reset if all shown
	if available.is_empty():
		_shown_indices.clear()
		for i in range(TIPS.size()):
			available.append(i)

	var idx: int = available[randi() % available.size()]
	_shown_indices.append(idx)
	return TIPS[idx]


## Reset the shown tips tracker (call on new session start).
static func reset_session() -> void:
	_shown_indices.clear()
