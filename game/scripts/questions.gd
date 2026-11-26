extends RefCounted
# The printable family question book reads this same file.
static var bank: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/vragen.json"))

static func deck(species: String, level: int, total: int) -> Array:
	var entry: Dictionary = bank[species]
	var cards := []
	if entry.has("grenzen"):
		var limits: Array = entry.grenzen[level-1]
		var inverse_first := randi()%2
		while cards.size()<total:
			var inverse := (cards.size()+inverse_first)%2==1
			var a: int
			var b: int
			var answer: int
			var question: String
			if species=="CycloVolt":
				a = randi_range(2,int(limits[0]))
				b = randi_range(2,int(limits[1]))
				answer = a if inverse else a*b
				question = ("%d ÷ %d = ?" % [a*b,b]) if inverse else ("%d × %d = ?" % [a,b])
			else:
				a = randi_range(1,int(limits[0]))
				b = randi_range(1,int(limits[1]))
				answer = a if inverse else a+b
				question = ("%d − %d = ?" % [a+b,b]) if inverse else ("%d + %d = ?" % [a,b])
			if cards.any(func(card): return card.q==question):
				continue
			cards.append({"q":question,"som":[a,b,question.split(" ")[1]],"choices":[str(answer),str(answer+randi_range(1,4)),str(answer-randi_range(1,mini(4,answer)))]})
	elif entry.has("vlaggen"):
		var span: Array = entry.groepen[level-1]
		var pool: Array = entry.vlaggen.slice(int(span[0]),int(span[1]))
		pool.shuffle()
		for flag: Array in pool.slice(0,total):
			var others := pool.duplicate()
			others.erase(flag)
			others.shuffle()
			cards.append({"q":"Van welk land is deze vlag?","flag":flag,"choices":[flag[0],others[0][0],others[1][0]]})
	else:
		var facts: Array = entry.vragen[level-1].duplicate()
		facts.shuffle()
		for fact: Array in facts.slice(0,total):
			cards.append({"q":fact[0],"choices":fact.slice(1)})
	for card: Dictionary in cards:
		card.answer = card.choices[0]
		card.choices.shuffle()
	return cards
