package com.barliesque.utils {
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class StringUtils {
		
		
		static public const TRIM_LEFT:int = 1;
		static public const TRIM_RIGHT:int = 2;
		static public const TRIM_SPACE:int = 4;
		static public const TRIM_CR:int = 8;
		static public const TRIM_LF:int = 16;
		static public const TRIM_NEWLINE:int = 32;
		static public const TRIM_TAB:int = 64;
		static public const TRIM_ALL:int = 127;
		
		/**
		 * Trim whitespace characters from the beginning and/or end of a string
		 * @param	string	The string string
		 * @param	options
		 * @return
		 */
		static public function trim(string:String, options:int = StringUtils.TRIM_ALL):String {
			var search:RegExp = new RegExp();
			
			// MAKE A REGEX BASED ON OPTIONS
			// USE STRING.SEARCH() ON LEFT / RIGHT
/*			
			if (options & TRIM_LEFT) {
				for (var first:int = 0; first < string.length; first++) {
					if (string.charAt(first) != trimChar) break;
				}
			}
			if (first == string.length) return "";
			for (var last:int = string.length -1; last >= 0; last--) {
				if (string.charAt(last) != trimChar) break;
			}
			return string.substring(first, last + 1);
*/
		}
		
		static public function replaceAll(string:String, searchPattern:*, replaceWith:*):String {
			var before:int;
			do {
				before = string.length;
				string = string.replace(searchPattern, replaceWith);
			} while (string.length != before);
			return string;
		}
		
		static public function filter(string:String, removeChars:String):String {
			
		}
		
		static public function restrict(string:String, allowChars:String):String {
			
		}
		
	}
}