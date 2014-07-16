package com.dodgems.grid {
	import com.barliesque.utils.applyText;
	import com.barliesque.utils.unescapeHTML;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	import com.greensock.easing.Quint;
	import com.greensock.TweenMax;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class CellCaption extends MovieClip {
		
		public var caption:TextField;
		private var captionText:String = "";
		private var captionHeight:Number;
		public var charsVisible:int = 0;
		private var page:GridPage;
		
		private const SIDE_MARGINS:Number = 50;
		private const BOTTOM_MARGIN:Number = 45;
		
		public function CellCaption() {
			page = parent as GridPage;
			mouseChildren = mouseEnabled = false;
			updateCaption();
		}
		
		public function get text():String { return captionText; }
		
		public function set text(value:String):void {
			//
			//  Fill in the whole caption to find out how tall the field will end up
			//
			captionText = unescapeHTML(value);
			charsVisible = value.length;
			caption.height = 0;
			updateCaption();
			captionHeight = Math.min(caption.height, caption.textHeight);
			
			//
			//  Now start from scratch!
			//
			charsVisible = 0;
			updateCaption();
			alpha = 1;
			var duration:Number = 0.2 + (captionText.length * 0.01);
			TweenMax.killTweensOf(this);
			TweenMax.to(this, duration, { charsVisible: captionText.length, onUpdate: updateCaption, ease:Linear.easeNone } );
		}
		
		private function updateCaption():void {
			applyText(" " + captionText.substr(0, charsVisible) + " ", caption, true, false, true);
			align();
		}
		
		public function align():void {
			if (page.currentCell) {
				caption.width = page.currentCell.width - SIDE_MARGINS;
				x = page.currentCell.x + SIDE_MARGINS * 0.5;
				y = page.currentCell.y + page.currentCell.height - captionHeight - BOTTOM_MARGIN;
			}
		}
		
		public function hide():void {
			if (caption.text.length > 0) {
				TweenMax.killTweensOf(this);
				TweenMax.to(this, 0.5, { alpha: 0, y: y + 20, ease:Quad.easeOut } );
			}
		}
		
	}
}