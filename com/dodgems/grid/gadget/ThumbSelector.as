package com.dodgems.grid.gadget {
	import com.barliesque.ImageLoader;
	import com.barliesque.utils.applyText;
	import com.dodgems.grid.HitDoctor;
	import com.dodgems.grid.HitDoctorEvent;
	import com.greensock.easing.Back;
	import com.greensock.easing.Quint;
	import com.greensock.TweenMax;
	import com.gskinner.geom.ColorMatrix;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class ThumbSelector extends MovieClip {
		
		// on-stage
		public var prevButton:SimpleButton;
		public var nextButton:SimpleButton;
		public var background:MovieClip;
		public var trigger:MovieClip;
		public var thumbTitle:TextField;
		
		private var hitDoctor:HitDoctor;	// Used purely to monitor when the mouse is over the trigger area to retract/show thumbnails
		private var panel:Sprite;
		
		private var thumbs:Array;		// Array of all thumbnail [ImageLoader] objects
		private var places:int;			// How many thumbs can be seen at a time
		private var firstThumb:int;		// Index of the first thumb currently in view
		
		private var redStroke:GlowFilter;
		private var blackStroke:GlowFilter;
		private var whiteStroke:GlowFilter;
		private var dimmed:ColorMatrixFilter;
		private var dropShadow:DropShadowFilter;
		private var innerShadow:DropShadowFilter;
		
		private var selectedFilters:Array;
		private var unselectedFilters:Array;
		private var overFilters:Array;
		private var currentThumb:ImageLoader;
		
		private const THUMB_X:int = 24;
		
		[Event(name='ThumbEvent.SELECTION', type="com.dodgems.common.ThumbEvent")]
		
		public function ThumbSelector() {
			redStroke = new GlowFilter(0xFF0000, 1, 5, 5, 20);
			blackStroke = new GlowFilter(0x4D0204, 1, 5, 5, 20);
			whiteStroke = new GlowFilter(0xFFFFFF, 1, 5, 5, 20);
			dropShadow = new DropShadowFilter(5, 45, 0x000000, 1, 3, 3, 1);
			innerShadow = new DropShadowFilter(0, 0, 0x000000, 1, 30, 30, 1.6, 2, true);
			dimmed = new ColorMatrixFilter(new ColorMatrix(null, -20, -20, -50));
			
			selectedFilters = [redStroke, dropShadow];
			unselectedFilters = [dimmed, innerShadow, blackStroke, dropShadow];
			overFilters = [whiteStroke, dropShadow];
			
			nextButton.addEventListener(MouseEvent.CLICK, changeSet, false, 0, true);
			prevButton.addEventListener(MouseEvent.CLICK, changeSet, false, 0, true);
			
			hitDoctor = new HitDoctor();
			hitDoctor.addPatient(trigger);
			trigger.visible = false;
			hitDoctor.enabled = false;
			
			//
			//  Contain the thumbnail selector in "panel" to make it retractable as a single entity
			//
			panel = new Sprite();
			addChild(panel);
			panel.addChild(background);
			panel.addChild(prevButton);
			panel.addChild(nextButton);
			panel.x = -panel.width;
			
			if (thumbTitle) {
				thumbTitle.visible = false;
				addChild(thumbTitle);
			}
		}
		
		private function changeSet(e:MouseEvent):void {
			if (e.target == nextButton) {
				firstThumb += places;
				positionThumbs( +1);
			} else {
				firstThumb -= places;
				positionThumbs( -1);
			}
		}
		
		
		public function show(xml:XML, tag:String, currentImage:String = ""):void {
			
			var thumb:ImageLoader;
			if (thumbs != null) for each (thumb in thumbs) {
				panel.removeChild(thumb);
				thumb.dispose();
			}
			
			thumbs = new Array();
			firstThumb = 0;
			
			for each (var thumbXML:XML in xml[tag]) {
				thumb = new ImageLoader(90, 60, ImageLoader.RESIZE_FILL, true);
				
				thumb.userData = thumbXML;
				thumb.x = THUMB_X;
				
				thumb.mouseChildren = false;
				thumb.addEventListener(MouseEvent.CLICK, thumbClick, false, 0, true);
				thumb.addEventListener(MouseEvent.MOUSE_OVER, thumbOver, false, 0, true);
				thumb.addEventListener(MouseEvent.MOUSE_DOWN, thumbDown, false, 0, true);
				thumb.addEventListener(MouseEvent.MOUSE_OUT, thumbOut, false, 0, true);
				
				var img:String = thumbXML.@img;
				if (img != null) {
					thumb.load(img);
				} else if (thumbXML.@stream != undefined) {
					// GET FIRST FRAME OF THE VIDEO AND FEED IT TO THE IMAGELOADER
				}
				
				if (img == currentImage || thumbXML.@id == currentImage) {
					thumbSelected(thumb, true);
					currentThumb = thumb;
					firstThumb = thumbs.length;
				} else {
					thumbSelected(thumb, false);
				}
				
				thumbs.push(thumb);
				panel.addChild(thumb);
			}
			
			positionThumbs(0);
			firstThumb -= Math.floor(places / 2);
			if (firstThumb < 0) firstThumb = 0;
			
			hitDoctor.enabled = true;
			hitDoctor.addEventListener(HitDoctorEvent.NO_PATIENT, retract, false, 0, true);
			panel.x = -panel.width;
			unRetract();
		}
		
		private function retract(e:HitDoctorEvent = null):void {
			TweenMax.to(panel, 1.0, { x: -panel.width, alpha: 0, ease: Quint.easeInOut } );
			hitDoctor.addEventListener(HitDoctorEvent.NEW_PATIENT, unRetract, false, 0, true);
		}
		
		private function unRetract(e:HitDoctorEvent = null):void {
			TweenMax.to(panel, 1.0, { x: 0, alpha: 1, ease: Quint.easeInOut } );
		}
		
		public function remove():void {
			hitDoctor.enabled = false;
			hitDoctor.removeEventListener(HitDoctorEvent.NEW_PATIENT, unRetract);
			hitDoctor.removeEventListener(HitDoctorEvent.NO_PATIENT, retract);
		}
		
		
		private function thumbSelected(thumb:ImageLoader, selected:Boolean):void {
			thumb.filters = selected ? selectedFilters : unselectedFilters;
			thumb.buttonMode = !selected;
		}
		
		public function selectThumb(thumb:ImageLoader = null, dispatch:Boolean = true, doRetract:Boolean = true):void {
			if (thumbTitle) thumbTitle.visible = false;
			if (thumb == null) {
				thumb = currentThumb;
				if ((thumb != null) && doRetract) retract();
			} else {
				if (currentThumb != thumb) {
					thumbSelected(thumb, true);
					if (currentThumb != null) thumbSelected(currentThumb, false);
					currentThumb = thumb;
				}
			}
			if (thumb == null) return;
			if (dispatch) dispatchEvent(new ThumbEvent(ThumbEvent.SELECTION, thumb));
		}
		
		public function selectFirst(dispatch:Boolean = true):void {
			selectThumb(thumbs[0], dispatch);
			if (dispatch) retract();
		}
		
		public function selectNext(wraparound:Boolean = true):void {
			var i:uint = thumbs.indexOf(currentThumb) + 1;
			if (i == thumbs.length) {
				if (!wraparound) return;
				i = 0;
			}
			selectThumb(thumbs[i]);
		}
		
		private function thumbClick(e:MouseEvent):void {
			selectThumb(e.target as ImageLoader);
		}
		
		
		private function thumbOver(e:MouseEvent):void {
			var thumb:ImageLoader = e.target as ImageLoader;
			if (thumb != currentThumb) {
				thumb.filters = overFilters;
			}
			
			if (thumbTitle) {
				if (thumb.userData.title) {
					applyText(thumb.userData.title, thumbTitle);
					thumbTitle.x = thumb.x + thumb.width + 10;
					thumbTitle.y = thumb.y + (thumb.height - Math.min(thumbTitle.height, thumbTitle.textHeight)) * 0.5;
					thumbTitle.visible = true;
				} else {
					thumbTitle.visible = false;
				}
			}
		}
		
		
		private function thumbDown(e:MouseEvent):void {
			var thumb:ImageLoader = e.target as ImageLoader;
			if (thumb == currentThumb) return;
			thumb.filters = selectedFilters;
		}
		
		
		private function thumbOut(e:MouseEvent):void {
			if (thumbTitle) thumbTitle.visible = false;
			var thumb:ImageLoader = e.target as ImageLoader;
			if (thumb == currentThumb) return;
			thumb.filters = unselectedFilters;
		}
		
		
		private function thumbID(xml:XML):String {
			if (xml.@id != undefined) {
				return xml.@id;
			} else if (xml.@img != undefined) {
				return xml.@img;
			} else if (xml.@url != undefined) {
				return xml.@url;
			}
			return null;
		}
		
		//--------------------------------------------------------
		
		public function dispose():void {
			thumbs = null;
			while (numChildren > 0) removeChildAt(0);
		}
		
		//--------------------------------------------------------
		
		override public function set width(value:Number):void {
			// WIDTH CANNOT BE CHANGED
		}
		
		override public function set height(value:Number):void {
			trigger.y = background.y = -5;
			trigger.height = background.height = value + 5;
			nextButton.y = value - 33;
			if (thumbs != null) positionThumbs(0);
		}
		
		private function positionThumbs(tweenDirection:int):void {
			var thumbHeight:Number = 70;
			var areaHeight:Number = (background.height - 94);
			places = Math.floor(areaHeight / thumbHeight);
			var center:Number = 40 + ((areaHeight - (thumbHeight * places)) * 0.5);
			
			// We only need the scroller buttons if there
			// isn't enough room for all the thumbnails
			nextButton.visible = prevButton.visible = (places < thumbs.length);
			if (places >= thumbs.length) firstThumb = 0;
			
			for (var i:int = 0; i < thumbs.length; i++) {
				
				var index:int = (firstThumb + i) % thumbs.length;
				if (index < 0) index += thumbs.length;
				var thumb:ImageLoader = thumbs[index];
				var targetY:Number;
				var targetX:Number;
				
				if (i < places) {
					// This thumbnail is *in*
					targetY = center + (thumbHeight * i);
					targetX = THUMB_X;
					thumb.visible = true;
					if (tweenDirection == 0) {
						//  No tweening, just put it where it needs to go
						thumb.y = targetY;
						thumb.x = THUMB_X;
					} else {
						//  Enter from below or above?
						thumb.y = (tweenDirection > 0) ? (height + thumbHeight) : (0 - thumbHeight * 2);
						thumb.x = targetX + (((i % 2) == 0) ? 100 : -100);
						TweenMax.to(thumb, 0.6, { y: targetY, x:targetX, delay: 0.3 + i * 0.2, ease:Back.easeOut, onComplete: thumbsMoved } );
					}
				} else {
					// This thumbnail is *out* ...was it already out?
					if (thumb.visible) {
						if (tweenDirection == 0) {
							thumb.visible = false;
						} else {
							// Exit to below or above?
							targetY = (tweenDirection > 0) ? (0 - thumbHeight * 2) : (height + thumbHeight);
							targetX = THUMB_X + (((i % 2) == 0) ? 100 : -100);
							TweenMax.to(thumb, 0.6, { y: targetY, x: targetX, ease:Back.easeIn } );
						}
					}
				}
				
				
				// Use the iterator to position the thumbnail
				// -1 < i < 0 ...	Thumbnail is somewhere between its correct placement and before the current set
				// i = 0 ...		Thumbnail is in position
				// 0 < i < 1 ...	Thumbnail is somewhere between its correct placement and after the current set
			}
			
		}
		
		private function thumbsMoved():void {
			firstThumb = firstThumb % thumbs.length;
			if (firstThumb < 0) firstThumb += thumbs.length;
		}
		
		public function get thumbCount():int {
			return (thumbs == null) ? 0 : thumbs.length;
		}
		
		//--------------------------------------------------------
		
	}
}