package com.dodgems.grid.gadget {
	import com.gaiaframework.api.Gaia;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class VideoControls extends MovieClip {
		
		public var slash:MovieClip;
		public var currentTime:TextField;
		public var duration:TextField;
		public var videoPos:MovieClip;
		public var fullscreenButton:SimpleButton;
		public var unMuteButton:SimpleButton;
		public var muteButton:SimpleButton;
		public var pauseButton:SimpleButton;
		public var playButton:SimpleButton;
		public var buffy:MovieClip;
		public var scrubby:MovieClip;
		public var share:MovieClip;
		public var facebook:SimpleButton;
		public var controlsBack:MovieClip;
		
		private var _margins:Number = 0;
		private var _bufferPercent:Number = 0;
		private var _playedPercent:Number = 0;
		private var _videoDuration:Number = NaN;
		
		private var _dragging:Boolean = false;
		
		/**
		 * Dispatched when the video position marker is manually positioned by the user
		 * @eventType flash.events.Event.CHANGE
		 */
		[Event(name="change", type="flash.events.Event")] 		
		
		
		public function VideoControls() {
			togglePlayPause(true);
			toggleMute(true);
			
			ButtonEvent.makeButton(videoPos);
			videoPos.addEventListener(ButtonEvent.DRAG, beginDrag, false, 0, true);
			videoPos.addEventListener(ButtonEvent.RELEASE, endDrag, false, 0, true);
			videoPos.addEventListener(ButtonEvent.RELEASE_OUTSIDE, endDrag, false, 0, true);
			
			scrubby.addEventListener(MouseEvent.MOUSE_DOWN, scrubbyClick, false, 0, true);
			buffy.mouseEnabled = false;
			
			playButton.addEventListener(MouseEvent.CLICK, togglePlayPause, false, 0, true);
			pauseButton.addEventListener(MouseEvent.CLICK, togglePlayPause, false, 0, true);
			muteButton.addEventListener(MouseEvent.CLICK, toggleMute, false, 0, true);
			unMuteButton.addEventListener(MouseEvent.CLICK, toggleMute, false, 0, true);
			
			facebook.addEventListener(MouseEvent.CLICK, visitFacebook, false, 0, true);
			share.mouseEnabled = false;
		}
		
		private function visitFacebook(e:MouseEvent):void {
			dispatchEvent(new Event("share"));
			
			//var rootURL:String = "http://www.facebook.com/share.php?u=http://www.dodgemotorsports.com";
			//if (Gaia.api) {
				//navigateToURL(new URLRequest(rootURL + Gaia.api.getValue()), "_blank");
			//} else {
				//  Testing outside Gaia...
				//navigateToURL(new URLRequest(rootURL));
			//}
		}
		
		private function beginDrag(e:MouseEvent):void {
			if (!_dragging) {
				_dragging = true;
				var dragRect:Rectangle = new Rectangle(scrubby.x, videoPos.y, scrubby.width, 0);
				videoPos.startDrag(false, dragRect);
			}
			
			_playedPercent = (videoPos.x - scrubby.x) / scrubby.width;
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function endDrag(e:MouseEvent = null):void {
			videoPos.stopDrag();
			_dragging = false;
		}
		
		private function scrubbyClick(e:MouseEvent):void {
			videoPos.x = mouseX;
			_playedPercent = (videoPos.x - scrubby.x) / scrubby.width;
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function togglePlayPause(paused:*):void {
			if (paused is Event) paused = !playButton.visible;
			pauseButton.visible = !paused;
			playButton.visible = paused;
		}
		
		public function toggleMute(mute:*):void {
			if (mute is Event) mute = !unMuteButton.visible;
			muteButton.visible = !mute;
			unMuteButton.visible = mute;
		}
		
		private function updateTimes():void{
			duration.text = minSec(_videoDuration);
			currentTime.text = minSec(_videoDuration * _playedPercent);
		}
		
		private function minSec(time:Number):String {
			if (isNaN(time)) return "--:--";
			var mins:int = int(time / 60);
			var sec:int = int(time) % 60;
			return mins + ":" + ((sec < 10) ? "0" : "" ) + sec;
		}
		
		public function reset():void {
			stopDrag();
			playedPercent = 0;
			bufferPercent = 0;
			togglePlayPause(true);
		}
		
		public function dispose():void {
			stopDrag();
			
			videoPos.removeEventListener(ButtonEvent.DRAG, beginDrag);
			videoPos.removeEventListener(ButtonEvent.RELEASE, endDrag);
			videoPos.removeEventListener(ButtonEvent.RELEASE_OUTSIDE, endDrag);
			scrubby.removeEventListener(MouseEvent.MOUSE_DOWN, scrubbyClick);
			playButton.removeEventListener(MouseEvent.CLICK, togglePlayPause);
			pauseButton.removeEventListener(MouseEvent.CLICK, togglePlayPause);
			muteButton.removeEventListener(MouseEvent.CLICK, toggleMute);
			unMuteButton.removeEventListener(MouseEvent.CLICK, toggleMute);
			facebook.removeEventListener(MouseEvent.CLICK, visitFacebook);
			
			while (numChildren > 0) removeChildAt(0);
		}
		
		//
		//  READ-ONLY PROPERTIES
		//
		
		public function get draggingPos():Boolean { return _dragging; }
		
		override public function get height():Number { return controlsBack.height; }
		override public function set height(value:Number):void {
			// CANNOT BE CHANGED!
		}
		
		//
		//  ACTIVE PROPERTIES
		//
		override public function get width():Number { return controlsBack.width; }
		override public function set width(value:Number):void {
			controlsBack.width = value;
			
			currentTime.x = 1 + _margins;
			slash.x = 32 + _margins;
			duration.x = 45 + _margins;
			
			pauseButton.x = 88 + _margins;
			playButton.x = 87 + _margins;
			
			scrubby.x = buffy.x = 115 + _margins;
			scrubby.width = value - 246 - (_margins * 2);
			videoPos.x = scrubby.x + (scrubby.width * _playedPercent);
			if (videoPos.x < scrubby.x) videoPos.x = scrubby.x;
			buffy.width = scrubby.width * _bufferPercent;
			
			fullscreenButton.x = value - 120 - _margins;
			muteButton.x = unMuteButton.x = value - 93 - _margins;
			share.x = value - 70 - _margins;
			facebook.x = value - 28 - _margins;
		}
		
		public function get bufferPercent():Number { return _bufferPercent; }
		public function set bufferPercent(value:Number):void {
			_bufferPercent = value;
			if (_bufferPercent > 1) _bufferPercent = 1;
			width = controlsBack.width;  // calls setter
		}
		
		public function get playedPercent():Number { return _playedPercent; }
		public function set playedPercent(value:Number):void {
			if (!_dragging) {
				_playedPercent = value;
				width = controlsBack.width;  // calls setter
			}
			updateTimes();
		}
		
		public function get videoDuration():Number { return _videoDuration; }
		
		public function set videoDuration(value:Number):void {
			_videoDuration = value;
			updateTimes();
		}
		
		public function get dragging():Boolean { return _dragging; }
		
		public function get margins():Number { return _margins; }
		
		public function set margins(value:Number):void {
			_margins = value;
			width = controlsBack.width;  // calls setter
		}
		
	}
}