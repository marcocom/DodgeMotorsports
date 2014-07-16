package com.barliesque.utils {
	/**
	 * @author David Barlia - david@barliesque.com
	 */
/*
	public class replaceAll {  // NOT A CLASS!	*/
		
		/**
		 * Performs string.replace() repeatedly, until all instances of the pattern have been replaced.
		 * @param	str				The original string
		 * @param	searchPattern	The pattern to search for.  Can be either a String or RegExp
		 * @param	replaceWith		String to replace search pattern with
		 * @return	Returns the modified string
		 */
		public function replaceAll(str:String, searchPattern:*, replaceWith:*):String {
			do {
				var before:String = str;
				str = str.replace(searchPattern, replaceWith);
			} while (str != before);
			return str;
		}
/*		
	}
	//*/
}

