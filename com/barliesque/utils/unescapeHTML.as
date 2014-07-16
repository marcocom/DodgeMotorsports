package com.barliesque.utils {
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	//public class unescapeHTML {  // NOT A CLASS!
		
		public function unescapeHTML(html:String, strictAscii:Boolean = false):String {
			
			replace(/&nbsp;/, 	" ");
			replace(/&amp;/, 	"&");
			replace(/&quot;/, 	'"');
			replace(/&lt;/, 	"<");
			replace(/&gt;/, 	">");
			
			replace(/&copy;/, 	String.fromCharCode(169));
			replace(/&reg;/, 	String.fromCharCode(174));
			replace(/&deg;/, 	String.fromCharCode(176));
			replace(/&plusmn;/,	String.fromCharCode(177));
			replace(/&micro;/,	String.fromCharCode(181));
			
			replace(/&Uuml;/,	String.fromCharCode(220));
			replace(/&uuml;/,	String.fromCharCode(252));
			
			replace(/&ndash;/, 	strictAscii ? " - " : 		String.fromCharCode(8211));
			replace(/&mdash;/, 	strictAscii ? "--" : 		String.fromCharCode(8212));
			replace(/&lsquo;/,	strictAscii ? "'": 			String.fromCharCode(8216));
			replace(/&rsquo;/, 	strictAscii ? "'" : 		String.fromCharCode(8217));
			replace(/&ldquo;/,	strictAscii ? '"' : 		String.fromCharCode(8220));
			replace(/&rdquo;/,	strictAscii ? '"' : 		String.fromCharCode(8221));
			replace(/&bull;/, 	strictAscii ? " * " : 		String.fromCharCode(8226));
			replace(/&hellip;/,	strictAscii ? "..." : 		String.fromCharCode(8230));
			replace(/&prime;/, 	strictAscii ? "'" : 		String.fromCharCode(8242));
			replace(/&Prime;/, 	strictAscii ? '"' : 		String.fromCharCode(8243));
			replace(/&trade;/, 	strictAscii ? "(TM)" : 		String.fromCharCode(8482));
			replace(/&infin;/, 	strictAscii ? "infinity" :	String.fromCharCode(8734));
			
			var first:int;
			var last:int;
			var char:int;
			var esc:String;
			do {
				first = html.search(/&#\d*;/);
				if (first >= 0) {
					last = html.indexOf(";", first) + 1;
					char = int(html.substring(first + 2, last - 1));
					esc = html.substring(first, last);
					html = html.replace(esc, String.fromCharCode(char));
				}
			} while (first >= 0);
			return html;
			
			function replace(searchPattern:*, replaceWith:*):void {
				var original:String;
				do {
					original = html;
					html = html.replace(searchPattern, replaceWith);
				} while (html != original);
			}
			
		}
		
	//}
}