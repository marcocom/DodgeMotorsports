package com.barliesque.utils {
	
	/**
	 * ...
	 * @author David Barlia
	 */
	
	/**
	 * Trim characters (spaces by default) from beginning and end of a string
	 * @param	original	The original string
	 * @param	trimChar	The character to trim away (default is space)
	 * @return
	 */
	public function trim(original:String, trimChar:String = " "):String {
		
		for (var first:int = 0; first < original.length; first++) {
			if (original.charAt(first) != trimChar) break;
		}
		if (first == original.length) return "";
		for (var last:int = original.length -1; last >= 0; last--) {
			if (original.charAt(last) != trimChar) break;
		}
		return original.substring(first, last + 1);
		
	}
}