package com.barliesque.utils {
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.events.Event;
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	
//	public class NOT_A_CLASS {
	 
	/**
	* Applies a block of text (optionally featuring html markup) to a textField (or series of textFields)
	* retaining formatting applied to the textField in the Flash IDE.  All formatting cascades across
	* a series of textFields.
	* @param	paragraph	The text to apply
	* @param	fields		One or many textFields--either a single textField, or an Array of TextFields
	*/
	public function applyText(paragraph:String, fields:*, autoSize:Boolean = true, allowScrolling:Boolean = false, enforceOriginalFormat:Boolean = false):void {
		var i:int;
		//
		// Helper functions
		//
		var dontScrollThatWay:Function;
		dontScrollThatWay = function(e:Event):void {
			// Don't allow mouse wheel to cause individual text fields to scroll!
			(e.target as TextField).scrollV = 0;
		}
		
		var tagName:Function = function(orig:String):String {
			return filterString(orig.toLowerCase(), "abcdefghijklmnopqrstuvwxyz_");
		}
		
		var textPart:Function = function(orig:String):int {
			return int(filterString(orig, "0123456789"));
		}
		
		paragraph = unescapeHTML(paragraph, false);
		
		//
		// Parameters: One TextField, or an array of TextFields
		//
		if (fields == null) return;
		if (fields is TextField) fields = [fields];
		var parts:int = fields.length;
		var format:TextFormat;
		for each(var field:TextField in fields) {
			
			if (field != null) {
				if (paragraph.length > 0) {
					if (paragraph.search("<") < 0) {
						//
						// Paragraph is *not* HTML...
						//
						format = field.getTextFormat();
						
						// Last field...
						if (i == parts - 1 && field) {
							if (autoSize) {
								field.autoSize = (format.align == "right") ? "right" : "left";
							}
							field.text = paragraph;
							field.setTextFormat(format);
							paragraph = "";
						} else {
							
							// Try to put all text into the field... whatever doesn't fit will be passed along to next part
							field.text = paragraph;
							field.setTextFormat(format);
							
							// Is paragraph too large for text field?
							if (field.bottomScrollV < field.numLines) {
								// Chop off whatever doesn't fit and save for the next field
								field.text = field.text.substr(0, field.getLineOffset(field.bottomScrollV) - 1);
								field.setTextFormat(format);
								paragraph = trim(paragraph.substr(field.text.length + 1));
							} else {
								// Paragraph completely fit into text field
								paragraph = "";
							}
						}
					} else {
						// Paragraph contains HTML
						field.condenseWhite = true;
						format = field.getTextFormat();
						
						// Last field...
						if (i == parts - 1) {
							if (autoSize) {
								field.autoSize = "left";
							}
							field.htmlText = paragraph;
							if (enforceOriginalFormat) field.setTextFormat(format);
							paragraph = "";
						} else {
							// Try to put all text into the field... whatever doesn't fit will be passed along to next part
							field.htmlText = paragraph;
							// Flash has re-written the HTML, so update paragraph
							paragraph = field.htmlText;
							if (enforceOriginalFormat) field.setTextFormat(format);
							
							// Is paragraph too large for text field?
							if (field.bottomScrollV < field.numLines) {
								// How many characters can fit in this field?
								var bottom:int = field.bottomScrollV;
								var visChars:int = (field.getLineOffset(bottom) - 1);
								
								// In the event of a single blank line of text, visChars will result as ZERO
								if (visChars == 0) {
									// Fix visChars to in
								}
								
								// Gather up tags that are still open at point of splice
								var openTags:Array = [];
								var pos:uint = 0;
								for (var j:int = 0; j < paragraph.length; j++) {
									if (paragraph.charAt(j) != "<") {
										++pos;
										if (pos >= visChars) break;
									} else {
										var closedAt:uint = paragraph.substr(j + 1).search(">") + 1;
										var htag:String = paragraph.substring(j,j + closedAt + 1);
										if (htag.charAt(1)=="/") {
											openTags.pop();
										} else {
											openTags.push(htag);
										}
										if (paragraph.substr(j, 4) == "</P>" || paragraph.substr(j, 6) == "<BR />") {
											j += closedAt;
											if (pos + 1 >= visChars) break;
										} else {
											j += closedAt;
										}
									}
								}
								
								// Allow any closing tags that follow immediately after
								while (paragraph.substr(j + 1, 2) == "</") {
									openTags.pop();
									closedAt = paragraph.substr(j + 1).search(">") + 1;
									j += closedAt;
									if (openTags.length == 0) break;
								}
								
								// This fixes an occasional odd problem where a two letter word gets cut in half...
								var c:String = paragraph.charAt(j + 1).toLowerCase();
								if (c >= "a" && c <= "z") --j;
								
								// Cut paragraph into two parts:
								// Whatever fits into this text field, and whatever must be saved for the next field
								var thisPart:String = paragraph.substr(0, j + 1);
								var nextPart:String = trim(paragraph.substr(j + 1));
								
								// Close tags in this text field, and re-open in the next...
								for (j = openTags.length-1; j >= 0; --j) {
									var end:int = openTags[j].search(" |>");
									thisPart += "</" + openTags[j].substring(1, end) + ">";
									nextPart = openTags[j] + nextPart;
								}
								field.htmlText = thisPart;
								paragraph = nextPart;
								
							} else {
								// Paragraph completely fit into text field
								paragraph = "";
							}
						}
					}
					if (!allowScrolling) {
						// Stop the mouse wheel from having scrolling power (except via the scroll bar!)
						field.addEventListener(Event.SCROLL, dontScrollThatWay, false, 0, true);
					}
					
				} else {
					// Clear unused text fields
					field.text = "";
				}
			}
		}
	}
	
	
}
//}