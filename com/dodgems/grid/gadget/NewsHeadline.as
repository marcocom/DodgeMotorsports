package com.dodgems.grid.gadget {
	import com.barliesque.utils.applyText;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class NewsHeadline extends MovieClip{
		
		// on-stage
		public var back:SimpleButton;
		public var title:TextField;
		public var clickForMore:MovieClip;
		public var divider:MovieClip;
		
		private var redTint:ColorTransform;
		private var noTint:ColorTransform;
		
		public var data:XML;
		
		public var id:String;
		
		public function NewsHeadline() {
			redTint = new ColorTransform(1, 0, 0);
			noTint = new ColorTransform();
			
			back.addEventListener(MouseEvent.MOUSE_OVER, tintClickMessage, false, 0, true);
			back.addEventListener(MouseEvent.MOUSE_OUT, unTintClickMessage, false, 0, true);
			
			title.mouseEnabled = false;
			divider.mouseEnabled = divider.mouseChildren = false;
			clickForMore.mouseEnabled = clickForMore.mouseChildren = false;
		}
		
		
		public function setData(dataXML:XML, id:String, side:String):void {
			data = XML(dataXML.toXMLString()); // Clone the XML
			var value:String = data.title;
			this.id = id;
			
			var originalHeight:Number = title.textHeight;
			applyText(value, title);
			var growth:Number = title.textHeight - originalHeight;
			clickForMore.y += growth;
			divider.y += growth;
			back.height += growth;
			
			if (data.link == undefined) {
				data.link = <link news={side}>BACK TO NEWS HEADLINES</link>;
			} else {
				var link:XML = data.link[0];
				data.link[0] = <link news={side}>BACK TO NEWS HEADLINES</link>;
				data.link[1] = link;
			}
		}
		
		
		private function unTintClickMessage(e:MouseEvent):void {
			clickForMore.transform.colorTransform = noTint;
		}
		
		private function tintClickMessage(e:MouseEvent):void {
			clickForMore.transform.colorTransform = redTint;
		}
		
	}
}