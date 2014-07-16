
/**
 * 
 * MORFsite - Flash Framework 
 * by David Barlia (c) 2009
 *
 * This is a modified version of the class VideoStream,
 * which is a part of the MORFsite framework by David Barlia.
 * 
 */


package com.barliesque {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamInfo;
	
	/// A class to handle playing video streams with options for resizing, masking and matting.  Dynamic cue point data is also possible, with the addition of the VideoCue class.
	public class VideoStream extends Sprite {
		
		public var autoPlay:Boolean;
		
		[Inspectable (variable="url", name="url", type="String", defaultValue="")]
		protected var _url:String;
		[Inspectable (variable="alignment", name="alignment", type="String", defaultValue="")]
		protected var _alignment:String = VideoStream.ALIGN_CENTER;
		[Inspectable (variable="resize", name="resize", type="String", defaultValue="RESIZE_NONE", enumeration="RESIZE_NONE,RESIZE_STRETCH,RESIZE_CROP,RESIZE_FILL,RESIZE_FIT")]
		protected var _resizing:String;
		private var _bufferTime:Number = 4.0;
		private var _mattColor:uint = 0x000000;
		private var _mattAlpha:Number = 1.0;
		private var _smoothing:Boolean = true;
		private var _loop:Boolean = false;
		private var _autostart:Boolean = true;
		[Inspectable (variable="gradientMask", name="gradientMask", type="Boolean", defaultValue="false")]
		
		private var _metaData:Object;
		private var _buffered:Boolean = false;
		private var _ready:Boolean = false;
		private var _currentCue:VideoCue;
		private var _defaultWidth:Number;
		private var _defaultHeight:Number;
		private var _duration:Number = NaN;
		private var _volume:Number = 1.0;
		
		protected var _videoHeight:int;
		protected var _videoWidth:int;
		
        protected var stream:NetStream;
        protected var connection:NetConnection;
		protected var video:Video;
		protected var cuePoints:Object;
		
		protected var placeholderFound:Boolean;
		protected var placeholder:BitmapData;
		protected var matt:Sprite;
		protected var videoMask:Sprite;
		
		
		// Resizing options...
		public static const RESIZE_NONE:String =		"RESIZE_NONE";
		public static const RESIZE_STRETCH:String =		"RESIZE_STRETCH";
		public static const RESIZE_FILL:String =		"RESIZE_FILL";
		public static const RESIZE_FIT:String =			"RESIZE_FIT";
        
		// Alignment...
		public static const ALIGN_TOP:String =			"TOP";
		public static const ALIGN_LEFT:String =			"LEFT";
		public static const ALIGN_RIGHT:String =		"RIGHT";
		public static const ALIGN_BOTTOM:String =		"BOTTOM";
		public static const ALIGN_CENTER:String =		"CENTER";
		public static const ALIGN_TOPLEFT:String =		"TOP_LEFT";
		public static const ALIGN_TOPRIGHT:String =		"TOP_RIGHT";
		public static const ALIGN_BOTTOMLEFT:String =	"BOTTOM_LEFT";
		public static const ALIGN_BOTTOMRIGHT:String =	"BOTTOM_RIGHT";
		
		// Events dispatched by a VideoStream
		[Event(name="VideoStreamEvent.BUFFER_FULL", type="com.barliesque.VideoStreamEvent")]
		[Event(name="VideoStreamEvent.BUFFER_FLUSH", type="com.barliesque.VideoStreamEvent")]
		[Event(name="VideoStreamEvent.BUFFER_EMPTY", type="com.barliesque.VideoStreamEvent")]
		[Event(name="VideoStreamEvent.VIDEO_ENDED", type="com.barliesque.VideoStreamEvent")]
		[Event(name="VideoStreamEvent.META_DATA", type="com.barliesque.VideoStreamEvent")]
		[Event(name="VideoStreamEvent.CUE_POINT", type="com.barliesque.VideoStreamEvent")]
		[Event(name="VideoStreamEvent.ERROR", type="com.barliesque.VideoStreamEvent")]
		[Event(name="VideoStreamEvent.READY", type="com.barliesque.VideoStreamEvent")]
		[Event(name="VideoStreamEvent.SEEK_POINT", type="com.barliesque.VideoStreamEvent")]
		                              
		//..............................................
		
		public function VideoStream(width:Number = NaN, height:Number = NaN, resizing:String = null) {
			
			var offsetX:Number = 0;
			var offsetY:Number = 0;
			var rot:Number = rotation;
			rotation = 0;
			
			if (numChildren > 0) {
				//
				//  Placeholder graphics are in the display list
				//
				
				var holdFilters:Array = this.filters;
				this.filters = [];
				var bounds:Rectangle = getBounds(null);
				_defaultWidth = (isNaN(width)) ? this.width : width;
				_defaultHeight = (isNaN(height)) ? this.height : height;
				offsetX = bounds.x;
				offsetY = bounds.y;
				//
				// Take a snapshot
				//
				var matrix:Matrix = new Matrix();
				matrix.translate( -offsetX, -offsetY);
				matrix.scale(scaleX, scaleY);
				placeholder = new BitmapData(_defaultWidth, _defaultHeight, true, 0x00000000);
				placeholder.draw(this, matrix, null, null, null, true);
				
				//
				// Remove image placeholder
				//
				while (numChildren > 0) removeChildAt(0);
				this.filters = holdFilters;
				
				_resizing = RESIZE_FILL;
				_alignment = ALIGN_CENTER;
				
			} else if (!(isNaN(width) || isNaN(height))) {
				//
				//  No placeholder, but we have default dimensions
				//  ...so we'll draw a placeholder
				//
				_defaultWidth = width;
				_defaultHeight = height;
				
				placeholder = new BitmapData(10, 10, false, 0xFFFFFFFF);	// Correct dimensions are applied below
				
				_resizing = RESIZE_FIT;
				_alignment = ALIGN_CENTER;
				
				
			} else {
				//
				//  No placeholder and no default size...
				//
				_defaultWidth = NaN;
				_defaultHeight = NaN;
				
				_resizing = RESIZE_NONE;
				_alignment = ALIGN_TOPLEFT;
				
			}
			
			//
			//  Create mask & matt from placeholder (if default dimensions are known)
			//
			if (!isNaN(_defaultWidth)) {
				//
				// Mask...
				//
				var maskBitmap:Bitmap = new Bitmap(placeholder, "auto", true);
				videoMask = new Sprite();
				videoMask.addChild(maskBitmap);
				addChild(videoMask);
				videoMask.cacheAsBitmap = false;	// Change this through the gradientMask setter

				//
				//  Matt
				//
				var mattBitmap:Bitmap = new Bitmap(placeholder, "auto", true);
				matt = new Sprite();
				matt.alpha = _mattAlpha;
				matt.addChild(mattBitmap);
				addChild(matt);
				mattBitmap.cacheAsBitmap = true;
				
				//
				//  Apply dimensions & offset
				//
				matt.width	= videoMask.width	= _defaultWidth;
				matt.height	= videoMask.height	= _defaultHeight;
				matt.x		= videoMask.x		= offsetX * scaleX;
				matt.y		= videoMask.y		= offsetY * scaleY;
				scaleX = scaleY = 1.0;
			}
			
			//
			//  Create the Video Object
			//
			if (isNaN(_defaultWidth)) {
				video = new Video();
			} else {
				video = new Video(_defaultWidth, _defaultHeight);
				video.mask = videoMask;
				video.cacheAsBitmap = true;
			}
			video.smoothing = _smoothing;
			video.x = offsetX;
			video.y = offsetY;
			video.visible = false;
			addChild(video);
			
			connection = new NetConnection();
			connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
			connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler, false, 0, true);
			
			mouseChildren = false;
			rotation = rot;
			if (resizing != null) _resizing = resizing;
		}
		
		//..............................................
		
		public function connect(serverCommand:String, ...args):void {
			args.unshift(serverCommand);
			connection.connect.apply(null, args);
		}
		
		//..............................................
		
		public function open(url:String, autoPlay:Boolean = true):void {
			_url = url;
			this.autoPlay = autoPlay;
			
			if (!connection.connected) connection.connect(null);
			
			if (stream == null) {
				stream = new NetStream(connection);
				stream.bufferTime = _bufferTime;
				stream.client = {onMetaData: onMetaData, onCuePoint: onCuePoint};
				stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
				stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler, false, 0, true);
				video.attachNetStream(stream);
			}
			
			_ready = false;
			_currentCue = null;
			_buffered = false;
			_metaData = null;
			_duration = NaN;
			video.visible = false;
			
			stream.play(_url);
			volume = _volume;  // calls setter
		}
		
		//--------------------------------------------------
		
		public function play(loop:Boolean = false):void {
			this.loop = loop; // calls setter
			stream.seek(0);
			stream.play(null);
			stream.resume();
		}
		
		public function pause():void {
			if (stream) stream.pause();
		}
		
		public function resume():void {
			if (stream) stream.resume();
		}
		
		public function togglePause():void {
			if (stream) stream.togglePause();
		}
		
		public function seek(time:Number):void {
			// why not add a message option? -- store the seek time as subscription data, and then check for that in netStatusHandler()
			if (stream) stream.seek(time);
		}
		
		public function get time():Number {
			return (stream != null) ? stream.time : NaN;
		}
		
		public function set time(value:Number):void {
			stream.seek(value);
		}
		
		//--------------------------------------------------EVENTS
		
		private function netStatusHandler(event:NetStatusEvent):void {
			
			if (event.info.level == "error") {
				trace('ERROR!  ' + event.info.code + '  url="' + _url + '" ');
				dispatchEvent(new VideoStreamEvent(VideoStreamEvent.ERROR, this, event.info.code));
				return;
			}
			
            switch (event.info.code) {
				case "NetConnection.Connect.Success":
                case "NetStream.Play.Start":
                    break;
					
                case "NetStream.Play.Stop":
					dispatchEvent(new VideoStreamEvent(VideoStreamEvent.VIDEO_ENDED, this));
                	break;
					
                case "NetStream.Buffer.Full":
					setBuffered(true);
                	break;
					
				case "NetStream.Buffer.Flush":
					setBuffered(false);
					break;
				
				case "NetStream.Buffer.Empty":
					setBuffered(false);
					break;
					
				case "NetStream.Seek.Notify":
					dispatchEvent(new VideoStreamEvent(VideoStreamEvent.SEEK_POINT, this));
					break;
				
				default:
					trace("> Unhandled NetStatus event: " + event.info.code);
					break;
            }
        }
		
        private function securityErrorHandler(event:SecurityErrorEvent):void {
			trace('ERROR!  Security Error: url="' + _url + '" ');
			dispatchEvent(new VideoStreamEvent(VideoStreamEvent.ERROR, this, "Security Error!"));
        }
		
		private function asyncErrorHandler(e:AsyncErrorEvent):void {
			trace('ERROR!  ASync Error: url="' + _url + '" ');
			dispatchEvent(new VideoStreamEvent(VideoStreamEvent.ERROR, this, "ASync Error! " + e.error));
			e.stopPropagation();
		}
        
		//........................
		
		private function onMetaData(md:Object):void {
			//
			// This serves as the official point of connection because
			// we will have received crucial size info about the video
			//
			_metaData = md;
			dispatchEvent(new VideoStreamEvent(VideoStreamEvent.META_DATA, this, _metaData));
			resize();
			
			_duration = md.duration;
			
			// Never buffer more than half the total video...
			if (_bufferTime > md.duration * 0.5) {
				bufferTime = md.duration * 0.5; // calls setter (to check if buffered status has changed)
			}
			
			if (!_ready) {
				//
				// The *first* time this event ocurrs, we can get things going...
				//
				stream.seek(0);
				if (autoPlay) {
					stream.play(null);
				} else {
					stream.pause();
				}
				video.visible = true;
				
				// Dispatch event
				_ready = true;
				dispatchEvent(new VideoStreamEvent(VideoStreamEvent.READY, this, _metaData));
			}
		}
		
		//---------------------------------------------------------------------------------------------
			
		private function onCuePoint(cue:Object):void {
			// An embedded cue point has been triggered
			_currentCue = new VideoCue(cue.name, cue.time, cue.parameters, cue.type == "event");
			_currentCue.setEmbedded(true);
			
			// Dispatch event or send message!
			dispatchEvent(new VideoStreamEvent(VideoStreamEvent.CUE_POINT, this, _currentCue));
		}
		
		//...................
		
		public function addCuePoint(name:String, time:Number, parameters:Object = null, isEvent:Boolean = true):void {
			if (cuePoints == null) {
				cuePoints = new Object();
				addEventListener(Event.ENTER_FRAME, checkCuePoints, false, 0, true);
			}
			var newCue:VideoCue = new VideoCue(name, time, parameters, isEvent);
			if (stream != null) newCue.oldTime = stream.time;
			cuePoints[name] = newCue;
		}
		
		//...................
		
		private function checkCuePoints(e:Event):void {
			if (stream == null) return;
			for each(var cue:VideoCue in cuePoints) {
				if (cue.checkCue(stream.time)) {
					// A dynamic cue point has been triggered
					_currentCue = cue;
					dispatchEvent(new VideoStreamEvent(VideoStreamEvent.CUE_POINT, this, _currentCue));
				}
			}
		}
		
		//...................
		
		public function getCueByName(name:String):VideoCue {
			return cuePoints[name];
		}
		
		//...................
		
		public function removeCuePoint(name:String = null):void {
			if (name != null) {
				delete cuePoints[name];
				if (emptyObject(cuePoints)) cuePoints = null;
			} else {
				cuePoints = null;
			}
			if (cuePoints == null) removeEventListener(Event.ENTER_FRAME, checkCuePoints);
		}
		
		//---------------------------------------------------------------------------------------------
		
		public function resize():void {
			_videoWidth =  (_metaData == null) ? _defaultWidth  : ((video.videoWidth == 0)  ? _metaData.width  : video.videoWidth);
			_videoHeight = (_metaData == null) ? _defaultHeight : ((video.videoHeight == 0) ? _metaData.height : video.videoHeight);
			if (matt != null) {
				matt.width = videoMask.width = _defaultWidth;
				matt.height = videoMask.height = _defaultHeight;
			}
			
			// Resize and position the video according to the resizing option
			// and either default or original video dimensions
			
			var videoAspect:Number = videoWidth / videoHeight;
			var defaultAspect:Number = _defaultWidth / _defaultHeight;
			var scale:Number;
			
			switch(_resizing) {
				case RESIZE_NONE:
					video.width = videoWidth;
					video.height = videoHeight;
					break;
				
				case RESIZE_STRETCH:
					video.width = _defaultWidth;
					video.height = _defaultHeight;
					break;
				
				case RESIZE_FIT:
					if (videoAspect > defaultAspect) {
						// Video is wider than default area
						video.width = _defaultWidth;
						scale = _defaultWidth / videoWidth;
						video.height = videoHeight * scale;
					} else {
						// Video is taller than default area
						video.height = _defaultHeight;
						scale = _defaultHeight / videoHeight;
						video.width = videoWidth * scale;
					}
					break;
					
				case RESIZE_FILL:
					if (videoAspect > defaultAspect) {
						// Video is wider than default area
						video.height = _defaultHeight;
						scale = _defaultHeight / videoHeight;
						video.width = videoWidth * scale;
					} else {
						// Video is taller than default area
						video.width = _defaultWidth;
						scale = _defaultWidth / videoWidth;
						video.height = videoHeight * scale;
					}
					break;
			}
			
			var offsetX:Number = (matt == null) ? 0 : matt.x;
			var offsetY:Number = (matt == null) ? 0 : matt.y;
			
			switch(_alignment) {
				case ALIGN_TOP:			video.x = (_defaultWidth - video.width) * 0.5;	video.y = 0;	break;
				case ALIGN_LEFT:		video.x = 0;	video.y = (_defaultHeight - video.height) * 0.5;	break;
				case ALIGN_RIGHT:		video.x = (_defaultWidth - video.width);	video.y = (_defaultHeight - video.height) * 0.5;	break;
				case ALIGN_BOTTOM:		video.x = (_defaultWidth - video.width) * 0.5;	video.y = (_defaultHeight - video.height);	break;
				case ALIGN_CENTER:		video.x = (_defaultWidth - video.width) * 0.5;	video.y = (_defaultHeight - video.height) * 0.5;	break;
				case ALIGN_TOPLEFT:		video.x = video.y = 0;  break;
				case ALIGN_TOPRIGHT:	video.x = (_defaultWidth - video.width);	video.y = 0;	break;
				case ALIGN_BOTTOMLEFT:	video.x = 0;	video.y = (_defaultHeight - video.height);	break;
				case ALIGN_BOTTOMRIGHT:	video.x = (_defaultWidth - video.width);	video.y = (_defaultHeight - video.height);	break;
			}
			video.x += offsetX;
			video.y += offsetY;
		}
		
		
		//--------------------------------------------------GETTER SETTERS
		
		/**
		 * [READ-ONLY] True when the video stream is ready
		 */
		public function get ready():Boolean {
			return _ready;
		}
		
		//........................
		
		/**
		 * [READ-ONLY] The url of the video stream
		 */
		public function get url():String {
			return _url;
		}
		
		//........................
		
		//override public function get visible():Boolean { return super.visible; }
		
		//override public function set visible(value:Boolean):void {
			//super.visible = value;
			//stream.receiveVideo(value);
		//}
		//
		//........................
		
		public function get currentCue():VideoCue { return _currentCue; }
		
		public function get currentFPS():Number { return stream.currentFPS; }
		
		//........................
		
		public function get resizing():String { return _resizing; }
		
		public function set resizing(value:String):void {
			// Only set the value if it's a valid resize value
			switch(value) {
				case RESIZE_NONE:
				case RESIZE_FIT:
				case RESIZE_FILL:
				case RESIZE_STRETCH:
					_resizing = value;
					resize();
					break;
					
				default:
					trace("WARNING:  Unrecognized resize value '" + value + "'");
			}
		}
		
		//........................
		
		public function get defaultWidth():Number { return _defaultWidth; }
		
		public function set defaultWidth(value:Number):void {
			if (isNaN(value)) _resizing = RESIZE_NONE;
			_defaultWidth = value;
			resize();
		}
		
		//........................
		
		public function get defaultHeight():Number { return _defaultHeight; }
		
		public function set defaultHeight(value:Number):void {
			if (isNaN(value)) _resizing = RESIZE_NONE;
			_defaultHeight = value;
			resize();
		}
		
		//........................
		
		override public function get width():Number { 
			if (isNaN(_defaultWidth)) {
				if (video == null) return super.width;
				return video.videoWidth;
			} else {
				return _defaultWidth;
			}
		}
		
		override public function set width(value:Number):void {
			if (isNaN(value)) _resizing = RESIZE_NONE;
			_defaultWidth = value;
			resize();
		}
		
		//........................
		
		override public function get height():Number {
			if (isNaN(_defaultHeight)) {
				if (video == null) return super.height;
				return video.videoHeight;
			} else {
				return _defaultHeight;
			}
		}
		
		override public function set height(value:Number):void {
			if (isNaN(value)) _resizing = RESIZE_NONE;
			_defaultHeight = value;
			resize();
		}
		
		//........................
		
		public function get videoWidth():int { return _videoWidth; }
		
		public function get videoHeight():int { return _videoHeight; }
		
		//........................
		
		public function get mattColor():uint { return _mattColor; }
		public function set mattColor(value:uint):void {
			_mattColor = value;
			if (matt != null) {
				var red:uint =		(value & 0xFF0000) >>> 16;
				var green:uint =	(value & 0x00FF00) >>> 8;
				var blue:uint =		value & 0x0000FF;
				matt.transform.colorTransform = new ColorTransform(0, 0, 0, 1, red, green, blue, 0);
			}
		}
		
		public function get mattAlpha():Number { return _mattAlpha; }
		public function set mattAlpha(value:Number):void {
			_mattAlpha = value;
			if (matt != null) matt.alpha = _mattAlpha;
		}
		
		//........................
		
		/**
		 * Specifies how long in seconds to buffer the stream before it may be played
		 */
		public function get bufferTime():Number { return _bufferTime; }
		public function set bufferTime(value:Number):void {
			_bufferTime = value;
			if (stream) {
				stream.bufferTime = value;
				setBuffered(stream.bufferTime < stream.bufferLength);
			}
		}

		public function get buffered():Boolean { return _buffered; }
		
		private function setBuffered(value:Boolean):void {
			if (_buffered == value) return;
			_buffered = value;
			
			if (_buffered) {
				dispatchEvent(new VideoStreamEvent(VideoStreamEvent.BUFFER_FULL, this));
				//video.visible = true;
			} else {
				if (stream.bufferLength == 0) {
					dispatchEvent(new VideoStreamEvent(VideoStreamEvent.BUFFER_EMPTY, this));
				} else {
					dispatchEvent(new VideoStreamEvent(VideoStreamEvent.BUFFER_FLUSH, this));
				}
			}
		}
		
		public function get currentBuffer():Number {
			return stream.bufferLength;
		}
		
		public function get streamInfo():NetStreamInfo {
			return stream.info;
		}
		
		public function get duration():Number { return _duration; }
		
		//........................
		
		public function get smoothing():Boolean { return _smoothing; }
		
		public function set smoothing(value:Boolean):void {
			_smoothing = value;
			if (video != null) video.smoothing = value;
		}
		
		//--------------------------------------------------
		
		public function set volume(value:Number):void {
			_volume = value;
			var s:SoundTransform = stream.soundTransform;
			s.volume = _volume;
			stream.soundTransform = s;
		}
		
		public function get volume():Number {
			return stream.soundTransform.volume;
		}
		
		//........................
		
		public function set pan(value:Number):void {
			var s:SoundTransform = stream.soundTransform;
			s.pan = value;
			stream.soundTransform = s;
		}
		
		public function get pan():Number {
			return stream.soundTransform.pan;
		}
		
		public function get loop():Boolean { return _loop; }
		
		public function set loop(value:Boolean):void {
			if (_loop != value) {
				_loop = value;
				if (_loop) {
					addEventListener(VideoStreamEvent.VIDEO_ENDED, doLoop, false, 0, true);
				} else {
					removeEventListener(VideoStreamEvent.VIDEO_ENDED, doLoop);
				}
			}
		}
		
		private function doLoop(e:VideoStreamEvent):void {
			stream.seek(0);
			stream.play(null);
		}
		
		//--------------------------------------------------
		
		public function get alignment():String { return _alignment; }
		
		public function set alignment(value:String):void {
			switch(value) {
				case ALIGN_TOP:
				case ALIGN_LEFT:
				case ALIGN_RIGHT:
				case ALIGN_BOTTOM:
				case ALIGN_CENTER:
				case ALIGN_TOPLEFT:
				case ALIGN_TOPRIGHT:
				case ALIGN_BOTTOMLEFT:
				case ALIGN_BOTTOMRIGHT:
					break;
				default:
					trace("WARNING!  Unrecognized alignment value: " + value);
					return;
			}
			_alignment = value;
			resize();
		}
		
		//--------------------------------------------------
		
		public function get autostart():Boolean { return _autostart; }
		
		public function set autostart(value:Boolean):void {
			_autostart = value;
		}
		
		//--------------------------------------------------
		
		public function get gradientMask():Boolean { return videoMask.cacheAsBitmap; }
		
		public function set gradientMask(value:Boolean):void {
			videoMask.cacheAsBitmap = value;
		}
		
		//--------------------------------------------------
		
		override public function get alpha():Number { return video.alpha; }
		
		override public function set alpha(value:Number):void {
			video.alpha = value;
		}
		
		//--------------------------------------------------
		
		public function close():void {
			pause();
			removeCuePoint();
			
			if (stream) {
				stream.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				stream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
				stream.close();
				stream = null;
			}
			
			_ready = false;
			_currentCue = null;
			_buffered = false;
			_metaData = null;
			_duration = NaN;
			
			loop = false;
			video.clear();
			video.visible = false;
		}
		
		public function dispose():void {
			while (numChildren > 0) removeChildAt(0);
			
			close();
			
			connection.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			connection.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			connection.close();
			connection = null;
			
			video = null;
			
			placeholder.dispose();
			placeholder = null;
			
			matt = null;
			videoMask = null;
		}
		
		private function emptyObject(obj:Object):Boolean {
			var child:*;
			for (child in obj) {
				if (child) return false;
			}
			return true;
		}		
		
		//--------------------------------------------------
		
	}
}
