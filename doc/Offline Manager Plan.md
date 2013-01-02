Object / Manager

Offline

	Store as 
	"app.model.User<34>": "haxe-serialised-string-of-user-object-with-id-34";

	For relations, only serialise the ID (not the object), and then make sure the related object is serialised / cached separately.

	For arrays of objects (one-to-many relations etc), serialise an array of the IDs, make sure each related object is also serialised / cached.