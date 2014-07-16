package com.barliesque {
	import com.greensock.TweenLite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class ImageLoader extends Sprite {
		
		//------------------------------------
		
		[Inspectable (variable="imageURL", name="imageURL", type="String", defaultValue="")]
		private var _imageURL:String;
		
		private var request:URLRequest;
		
		protected var loader:Loader;
		protected var oldLoader:Loader;
		protected var cache:Object = { };
		
		static public const CACHE_AUTO:int = 0;
		static public const CACHE_IMAGE:int = 1;
		static public const CACHE_NEVER:int = -1;
		
		protected var _imageMask:Bitmap;
		protected var old_imageMask:Bitmap;
		
		protected var placeholderWidth:Number;
		protected var placeholderHeight:Number;
		protected var placeholderX:Number;
		protected var placeholderY:Number;
		
		public var resizing:int = RESIZE_FIT;
		public static const RESIZE_NONE:int = 0;
		public static const RESIZE_FIT:int = 1;
		public static const RESIZE_FILL:int = 2;
		
		public var alignV:int = ALIGN_CENTER;
		public var alignH:int = ALIGN_CENTER;
		public static const ALIGN_LEFT:int = -1;
		public static const ALIGN_RIGHT:int = 1;
		public static const ALIGN_TOP:int = -1;
		public static const ALIGN_BOTTOM:int = 1;
		public static const ALIGN_CENTER:int = 0;
		public static const ALIGN_TO_PAN:int = 2;
		protected var _panH:Number = 0.5;
		protected var _panV:Number = 0.5;
		
		private var _imageWidth:Number;
		private var _imageHeight:Number;
		
		private var _smoothing:Boolean = true;
		
		[Event(name="ImageLoader.IMAGE_LOADED", type="com.barliesque.ImageLoader")]
		public static const IMAGE_LOADED:String = "ImageLoader.IMAGE_LOADED";
		
		[Event(name="ImageLoader.IMAGE_IN_FULL", type="com.barliesque.ImageLoader")]
		public static const IMAGE_IN_FULL:String = "ImageLoader.IMAGE_IN_FULL";
		
		public var transitionFunc:Function;
		public var fadeTime:Number = 0.5;
		
		public var userData:*;
		
		//------------------------------------
		
		public function ImageLoader(width:Number = NaN, height:Number = NaN, resizing:int = ImageLoader.RESIZE_NONE, masking:Boolean = false) {
			this.resizing = resizing;
			
			var bounds:Rectangle = getBounds(null);
			placeholderWidth = (isNaN(width)) ? this.width : width;
			placeholderHeight = (isNaN(height)) ? this.height : height;
			placeholderX = getBounds(null).x;
			placeholderY = getBounds(null).y;
			
			// Create a mask
			if (masking) {
				var reset:Matrix = new Matrix();
				reset.translate( -placeholderX, -placeholderY);
				var maskBitmap:BitmapData;
				
				if (!isNaN(width) && !isNaN(height)) {
					maskBitmap = new BitmapData(width, height, true, 0);
					maskBitmap.fillRect(new Rectangle(0, 0, width, height), 0xFFFFFFFF);
				} else {
					maskBitmap = new BitmapData(this.width, this.height, true, 0);
					maskBitmap.draw(this, reset);
				}
				
				_imageMask = new Bitmap(maskBitmap);
				old_imageMask = new Bitmap(maskBitmap);
				old_imageMask.x = _imageMask.x = placeholderX;
				old_imageMask.y = _imageMask.y = placeholderY;
				old_imageMask.visible = _imageMask.visible = false;
			}
			
			// Remove image placeholder
			while (numChildren > 0) removeChildAt(0);
			scaleX = scaleY = 1.0;
			
			//
			// Add mask to the display list
			//
			if (masking) {
				addChild(_imageMask);
				addChild(old_imageMask);
			}
			
			transitionFunc = fadeIn;
		}
		
		
		public function load(url:String, caching:int = ImageLoader.CACHE_AUTO):void {
			
			if (caching == CACHE_NEVER) {
				url += (url.search("\\?") > 0) ? "&" : "?";
				url += "nochache=" + getTimer();
			}
			request = new URLRequest(url);
			
			depricateCurrentImage();
			
			//
			//  Load the image!
			//
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadingComplete, false, 0, true);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadingError, false, 0, true);
			loader.load(request);
			loader.mask = _imageMask;
			loader.alpha = 0;
			
			if (caching == CACHE_IMAGE) cache[url] = loader;
			_imageURL = url;
		}
		
		
		private function depricateCurrentImage():void {
			if (loader) {
				//
				// An image has already been loaded...
				//
				if (loader.alpha == 0) {
					// Previous loader must have been interrupted...
					try {
						loader.close();
					} catch (e:Error) { }
					loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loadingComplete);
				}
				//
				// Depricate the old image...
				//
				if (oldLoader) {
					if (oldLoader.parent) removeChild(oldLoader);
				}
				oldLoader = loader;
				oldLoader.mask = old_imageMask;
			}
		}
		
		
		private function loadingError(e:IOErrorEvent):void {
			trace("ERROR!  ImageLoader(" + name + ") could not load: " + request.url);
		}
		
		
		private function loadingComplete(e:Event):void {
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loadingComplete);
			
			transitionFunc(loader);
			smoothing = _smoothing;  // calls setter
			
			dispatchEvent(e);	// Pass along the original Event.COMPLETE
			addChild(loader);
			alignAndResize();
			
			dispatchEvent(new Event(IMAGE_LOADED));
		}
		
		
		public function useImage(bitmapData:BitmapData):void {
			depricateCurrentImage();
			
			//
			//  *Pretend* to load a new image
			//
			loader = new Loader();
			loader.mask = _imageMask;
			loader.alpha = 0;
			//
			//  But instead of loading, we'll simply add the image directly
			//
			loader.addChild(new Bitmap(bitmapData, "auto", _smoothing));
			loadingComplete(new Event(Event.COMPLETE));
		}
		
		
		protected function alignAndResize():void {
			//
			// Resize the image within the placeholder area
			//
			if (loader == null) return;
			if (loader.height == 0) return;
			
			loader.scaleX = loader.scaleY = 1.0;
			loader.x = loader.y = 0;
			
			var aspect:Number = loader.width / loader.height;
			var scale:Number;
			switch (resizing) {
				case RESIZE_NONE: {
					scale = 1.0;
					break;
				}
				case RESIZE_FIT: {
					if (aspect > (placeholderWidth / placeholderHeight)) {
						// Image is wider than placeholder
						scale = placeholderWidth / loader.width;
					} else {
						// Image is taller than placeholder
						scale = placeholderHeight / loader.height;
					}
					break;
				}
				case RESIZE_FILL: {
					if (aspect > (placeholderWidth / placeholderHeight)) {
						// Image is wider than placeholder
						scale = placeholderHeight / loader.height;
					} else {
						// Image is taller than placeholder
						scale = placeholderWidth / loader.width;
					}
					break;
				}
			}
			
			loader.scaleX = loader.scaleY = scale;
			
			//
			// Align the image within the placeholder area
			//
			switch (alignH) {
				case ALIGN_LEFT: {
					loader.x = placeholderX;
					break;
				}
				case ALIGN_RIGHT: {
					loader.x = (placeholderWidth - loader.width) + placeholderX;
					break;
				}
				case ALIGN_CENTER: {
					loader.x = (placeholderWidth - loader.width) * 0.5 + placeholderX;
					break;
				}
				case ALIGN_TO_PAN: {
					loader.x = (placeholderWidth - loader.width) * _panH + placeholderX;
					break;
				}
			}
			switch (alignV) {
				case ALIGN_TOP: {
					loader.y = placeholderY;
					break;
				}
				case ALIGN_BOTTOM: {
					loader.y = (placeholderHeight - loader.height) + placeholderY;
					break;
				}
				case ALIGN_CENTER: {
					loader.y = (placeholderHeight - loader.height) * 0.5 + placeholderY;
					break;
				}
				case ALIGN_TO_PAN: {
					loader.y = (placeholderHeight - loader.height) * _panV + placeholderY;
					break;
				}
			}
		}
		
		private function fadeIn(clip:Loader):void {
			// A nice quick fade in...
			TweenLite.to(clip, fadeTime, { alpha:1.0, onComplete:imageInFull } );
		}
		
		public function imageInFull():void {
			dispatchEvent(new Event(IMAGE_IN_FULL));
			
			if (oldLoader) {
				if (oldLoader.parent) removeChild(oldLoader);
				TweenLite.killTweensOf(oldLoader);
				oldLoader = null;
			}
		}
		
		public function dispose():void {
			while (numChildren > 0) removeChildAt(0);
			clearCache();
			cache = null;
			try {
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loadingError);
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loadingComplete);
				loader.close();
			} catch (e:Error) { }
			loader = null;
			oldLoader = null;
			request = null;
		}
		
		public function clearCache():void {
			for (var key:String in cache) delete cache[key];
		}
		
		
		override public function getRect(targetCoordinateSpace:DisplayObject):Rectangle {
			if (_imageMask) {
				return _imageMask.getRect(targetCoordinateSpace);
			} else {
				return super.getRect(targetCoordinateSpace);
			}
		}
		
		//------------------------------------------------------------------------
		//  READ-ONLY PROPERTIES
		//------------------------------------------------------------------------
		
		public function get loaded():Boolean {
			if (loader == null) return false;
			return (loader.contentLoaderInfo.bytesLoaded == loader.contentLoaderInfo.bytesTotal);
		}
		
		public function get imageMask():Bitmap { return _imageMask; }
		
		//  Return the image dimensions-- unscaled
		public function get imageWidth():Number { return (loader ? (loader.width / loader.scaleX) : 0); }
		public function get imageHeight():Number { return (loader ? (loader.height / loader.scaleY) : 0); }
		
		
		//------------------------------------------------------------------------
		//  ACTIVE PROPERTIES
		//------------------------------------------------------------------------
		
		public function get smoothing():Boolean {
			return _smoothing;
		}
		
		public function set smoothing(smooth:Boolean):void {
			_smoothing = smooth;
			
			if (loader == null) return;
			
			var smoothBitmap:Bitmap = Bitmap(loader.getChildAt(0));
			if (smoothBitmap == null) return;
			
			smoothBitmap.smoothing = smooth;
		}
		
		//.....................
		
		public function get imageURL():String { return _imageURL; }
		
		public function set imageURL(value:String):void {
			_imageURL = value;
			if (_imageURL == "") {
				dispose();
			} else {
				load(_imageURL);
			}
		}
		
		//.....................
		
		override public function get width():Number {
			if (_imageMask) {
				//	Report dimensions based on *masking*
				return _imageMask.width;
			} else {
				return super.width;
			}
		}
		
		override public function set width(value:Number):void {
			if (value < 1) value = 1;
			if (_imageMask) {
				//	Update mask to reflect changes to dimensions
				_imageMask.width = placeholderWidth = value;
				if (old_imageMask) old_imageMask.width = value;
				alignAndResize();
			} else {
				super.width = value;
			}
		}
		
		override public function get height():Number {
			if (_imageMask) {
				//	Report dimensions based on *masking*
				return _imageMask.height;
			} else {
				return super.height;
			}
		}
		
		override public function set height(value:Number):void {
			if (value < 1) value = 1;
			if (_imageMask) {
				//	Update mask to reflect changes to dimensions
				_imageMask.height = placeholderHeight = value;
				if (old_imageMask) old_imageMask.height = value;
				alignAndResize();
			} else {
				super.height = value;
			}
		}
		
		//.....................
		
		public function get panH():Number { return _panH; }
		
		public function set panH(value:Number):void {
			if (value >= 0 && value <= 1) _panH = value;
			if (alignH == ALIGN_TO_PAN) alignAndResize();
		}
		
		public function get panV():Number { return _panV; }
		
		public function set panV(value:Number):void {
			if (value >= 0 && value <= 1) _panV = value;
			if (alignV == ALIGN_TO_PAN) alignAndResize();
		}
		
		//
		//----------------------------------------------------------------------
		
	}
}