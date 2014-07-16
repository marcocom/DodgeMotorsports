package com.barliesque.utils {
	
	/**
	* ...
	* @author David Barlia
	*/
	public function filterString(original:String, keepChars:String):String {
		
		var o:int;
		var k:int;
		var lastO:int = original.length - 1;
		var lastK:int = keepChars.length - 1;
		var filtered:String = "";
		
		for (o = 0; o <= lastO; o++) {
			for (k = 0; k <= lastK; k++) {
				if (original.charAt(o) == keepChars.charAt(k)) {
					filtered += original.charAt(o);
					break;
				}
			}
		}
		return filtered;
		
	}
	
}
