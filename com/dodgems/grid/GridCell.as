package com.dodgems.grid {
	import com.barliesque.ImageLoader;
	import com.barliesque.utils.applyText;
	import com.barliesque.utils.unescapeHTML;
	import com.greensock.easing.*;
	import com.greensock.TweenMax;
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class GridCell extends ImageLoader {
		
		public var data:XML;
		public var gadgetMask:Bitmap;
		
		public var titleBar:MovieClip;
		
		private var titleAlign:String;
		
		public var gadgetData:Object = { };
		private var overrideWidth:Number = NaN;
		private var overrideHeight:Number = NaN;
		
		//------------------------------------------
		
		public function GridCell() {
			super(NaN, NaN, ImageLoader.RESIZE_FILL, true);
			
			alignH = ALIGN_TO_PAN;
			alignV = ALIGN_TO_PAN;
			
			gadgetMask = new Bitmap(imageMask.bitmapData);
			gadgetMask.visible = false;
			addChild(gadgetMask);
			
			cacheAsBitmap = true;
		}
		
		
		public function init(data:XML):void {
			this.data = data;
			
			//  Default to center if position isn't specified
			if (data.@pos == undefined) data.@pos = "50";
			
			addEventListener(ImageLoader.IMAGE_LOADED, titleBarOnTop, false, 0, true);
			load(data.@img, ImageLoader.CACHE_IMAGE);
			
			if (data.title != undefined) {
				
				titleBar = new CellTitleBar();
				titleBar.alpha = 0;
				addChild(titleBar);
				
				applyText(unescapeHTML(data.title), titleBar.title);
				titleAlign = String((data.title.@align == undefined) ? "top" : data.title.@align).substr(0, 1).toLowerCase();
				
				switch (String(data.title.@bar)) {
					case "none":	titleBar.bar1.alpha = titleBar.bar2.alpha = 0.0;	break;
					default:		titleBar.bar1.alpha = titleBar.bar2.alpha = 1.0;	break;
				}
				
			} else if (titleBar) {
				
				TweenMax.killTweensOf(titleBar);
				removeChild(titleBar);
				titleBar = null;
			}
			
			resize();
		}
		
		private function titleBarOnTop(e:Event):void {
			//
			//  Sometimes a slowly loaded image will cover up the title bar when it fades in.
			//  This fixes that...
			//
			removeEventListener(ImageLoader.IMAGE_LOADED, titleBarOnTop);
			if (titleBar) {
				setChildIndex(titleBar, numChildren - 1);
			}
		}
		
		//------------------------------------------
		
		public function resize():void {
			var pan:Array = String(data.@pos).split(",");
			if (pan.length == 1) pan[1] = int(pan[0]);
			_panH = pan[0] / 100;
			_panV = pan[1] / 100;
			
			alignAndResize();
			updateTitleBar();
		}
		
		
		public function changeImage(img:String, pos:String = null):void {
			data.@img = img;
			if (pos != null) data.@pos = pos;
			load(img);
			
			var pan:Array = String(data.@pos).split(",");
			if (pan.length == 1) pan[1] = int(pan[0]);
			pan[0] = Number(pan[0]) / 100;
			pan[1] = Number(pan[1]) / 100;
			TweenMax.to(this, 0.5, { panH: pan[0], panV: pan[1], ease: Quint.easeOut } );
		}
		
		//----------------------------------------
		
		public function sizeOverride(width:Number = NaN, height:Number = NaN):void {
			overrideWidth = width;
			overrideHeight = height;
		}
		
		override public function get imageWidth():Number { 
			return isNaN(overrideWidth) ? super.imageWidth : overrideWidth; 
		}
		
		override public function get imageHeight():Number { 
			return isNaN(overrideHeight) ? super.imageHeight : overrideHeight;
		}
		
		//----------------------------------------
		
		private function updateTitleBar():void {
			if (titleBar == null) return;

			if ((getChildIndex(titleBar) + 1) < numChildren) setChildIndex(titleBar, numChildren - 1);
			var title:TextField = titleBar.title;
			
			//titleBar.bar1.visible = titleBar.bar2.visible = (titleBar.title.text.length > 0 && gadgetMask.width > 4);
			
			var titleWidth:Number = Math.min(title.width, title.textWidth);
			
			switch (titleAlign) {
				case "t":
					titleBar.bar1.width = titleBar.bar2.width = imageMask.width;
					titleBar.x = 0;
					titleBar.y = 0;
					title.x = imageMask.width - titleWidth - 8;
					break;
				case "b":
					titleBar.bar1.width = titleBar.bar2.width = imageMask.width;
					titleBar.x = 0;
					titleBar.y = imageMask.height - titleBar.height + 1;
					title.x = imageMask.width - titleWidth - 8;
					break;
				case "l":
					titleBar.bar1.width = titleBar.bar2.width = imageMask.height;
					titleBar.x = titleBar.bar1.height;
					titleBar.y = 0;
					titleBar.rotation = 90;
					title.x = 8;
					break;
				case "r":
					titleBar.bar1.width = titleBar.bar2.width = imageMask.height;
					titleBar.x = imageMask.width;
					titleBar.y = 0;
					titleBar.rotation = 90;
					title.x = imageMask.height - titleWidth - 8;
					break;
			}
			
			//
			// Minimize the title bar when there's no room for it
			//
			showTitleBar(!(titleBar.bar1.width < titleWidth || imageMask.height < titleBar.bar1.height || imageMask.width < titleBar.bar1.height));
		}
		
		
		public function showTitleBar(show:Boolean):void {
			if (titleBar) {
				TweenMax.to(titleBar, 0.4, { alpha: (show ? 1 : 0) } );
			}
		}
		
		//------------------------------------------
		
		override public function set x(value:Number):void {
			super.x = value;
			updateTitleBar();
		}
		
		override public function set y(value:Number):void {
			super.y = value;
			updateTitleBar();
		}
		
		override public function set width(value:Number):void {
			super.width = value;
			gadgetMask.width = value;
			updateTitleBar();
		}
		
		override public function set height(value:Number):void {
			super.height = value;
			gadgetMask.height = value;
			updateTitleBar();
		}
		
		//------------------------------------------
		
		override public function toString():String {
			return "[GridCell " + name + "]";
		}
		
		//private function loaded(e:Event):void {
			//
			//if (overflowX > overflowY) {
				//TweenMax.to(loader, 3.0, {x:-overflowX, ease:Quad.easeInOut, yoyo:true, repeat:-1});
			//} else {
				//TweenMax.to(loader, 3.0, {y:-overflowY, ease:Quad.easeInOut, yoyo:true, repeat:-1});
			//}
		//}
		
	}
}