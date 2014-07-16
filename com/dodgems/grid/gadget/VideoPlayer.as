package com.dodgems.grid.gadget {
	import com.barliesque.VideoStream;
	import com.barliesque.VideoStreamEvent;
	import com.greensock.easing.Quint;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import com.greensock.TweenMax;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class VideoPlayer extends MovieClip {
		
		// on-stage
		
		public var startButton:SimpleButton;
		public var loadingIndicator:MovieClip;
		public var video:VideoStream;
		public var controls:VideoControls;
		
		private var _controlsMarginX:Number = 0;
		private var _controlsMarginY:Number = 0;
		private var _isPlaying:Boolean = false;
		
		private var isFullscreen:Boolean;
		private var savedRectangle:Rectangle;
		private var savedParent:DisplayObjectContainer;
		private var savedIndex:int;
		
		public var controlsAvailable:Number = 0.0;
		
		public function VideoPlayer() {
			loadingIndicator.visible = false;
			startButton.visible = false;
			video.resizing = VideoStream.RESIZE_STRETCH;
			video.alignment = VideoStream.ALIGN_CENTER;
			video.mattAlpha = 0;
			video.visible = false;
			
			addEventListener(Event.ADDED_TO_STAGE, onAdded, false, 0, true);
		}
		
		private function onAdded(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			video.addEventListener(VideoStreamEvent.BUFFER_EMPTY, showLoading, false, 0, true);
			video.addEventListener(VideoStreamEvent.BUFFER_FULL, hideLoading, false, 0, true);
			video.addEventListener(VideoStreamEvent.BUFFER_FLUSH, hideLoading, false, 0, true);
			
			controls.playButton.addEventListener(MouseEvent.CLICK, playVideo, false, 0, true);
			controls.pauseButton.addEventListener(MouseEvent.CLICK, pauseVideo, false, 0, true);
			controls.muteButton.addEventListener(MouseEvent.CLICK, muteVideo, false, 0, true);
			controls.unMuteButton.addEventListener(MouseEvent.CLICK, unMuteVideo, false, 0, true);
			
			controls.fullscreenButton.addEventListener(MouseEvent.CLICK, toggleFullscreen, false, 0, true);
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, endFullscreen, false, 0, true);
			
			video.addEventListener(VideoStreamEvent.VIDEO_ENDED, videoEnded, false, 0, true);
			
			startButton.addEventListener(MouseEvent.CLICK, startButtonClick, false, 0, true);
		}
		
		private function videoEnded(e:VideoStreamEvent):void {
			endFullscreen(null);
			showControls(false);
			video.mattAlpha = 1;
			_isPlaying = false;
		}
		
		private function unMuteVideo(e:MouseEvent):void {
			video.volume = 0;
		}
		
		
		private function muteVideo(e:MouseEvent):void {
			video.volume = 1;
		}
		
		private function startButtonClick(e:MouseEvent):void {
			startButton.visible = false;
			video.visible = controls.visible = true;
			playVideo(e);
		}
		
		private function toggleFullscreen(ignored:MouseEvent):void {
			if (stage.fullScreenWidth == 0) return;
			if (!isFullscreen) {
				//
				//  GO FULLSCREEN!
				//
				savedParent = parent;
				savedIndex = parent.getChildIndex(this);
				savedRectangle = getBounds(parent);
				
				stage.addChild(this);
				
				stage.fullScreenSourceRect = getBounds(stage);
				stage.displayState = StageDisplayState.FULL_SCREEN;
				isFullscreen = true;
			} else {
				//
				//  RETURN FROM FULLSCREEN
				//
				stage.displayState = StageDisplayState.NORMAL;
			}
		}
		
		private function endFullscreen(ignored:FullScreenEvent):void {
			if (isFullscreen) {
				savedParent.addChildAt(this, savedIndex);
				x = savedRectangle.x;
				y = savedRectangle.y;
				width = savedRectangle.width;
				height = savedRectangle.height;
				isFullscreen = false;
				stage.displayState = StageDisplayState.NORMAL;
			}
		}
		
		private function hideLoading(...ignore):void {
			loadingIndicator.visible = false;
		}
		
		public function showControls(show:Boolean):void {
			TweenMax.to(this, 0.8, { controlsAvailable: show ? 1 : 0,
				ease: Quint.easeInOut, onUpdate: tweenControls, overwrite: 2} );
		}
		
		private function tweenControls():void {
			controls.alpha = controlsAvailable;
			height = video.height;	// calls setter
			dispatchEvent(new Event(Event.RESIZE));
		}
		
		private function showLoading(...ignore):void {
			loadingIndicator.visible = true;
		}
		
		public function open(url:String, autoPlay:Boolean = true, cues:XMLList = null):void {
			close();
			
			if (cues) {
				var i:int = 1;
				for each (var cue:XML in cues) {
					var time:Array = String(cue.@time).split(":");
					var duration:Number = (cue.@duration == undefined) ? 5 : cue.@duration;
					if (time.length == 1) {
						video.addCuePoint("cue" + (i++), Number(time[0]), { caption: cue } );
						video.addCuePoint("cue" + (i++), Number(time[0]) + duration, { caption: "" } );
					} else {
						video.addCuePoint("cue" + (i++), (time[0] * 60) + Number(time[1]), { caption: cue } );
						video.addCuePoint("cue" + (i++), (time[0] * 60) + Number(time[1]) + duration, { caption: "" } );
					}
				}
			}
			video.visible = controls.visible = autoPlay;
			startButton.visible = !autoPlay;
			video.open(url, autoPlay);
			addEventListener(Event.ENTER_FRAME, updateControls, false, 0, true);
			controls.addEventListener(Event.CHANGE, controlVideo, false, 0, true);
			controls.togglePlayPause(false);
			video.bufferTime = 6;
			video.mattAlpha = 1;
			showControls(!autoPlay);
			_isPlaying = autoPlay;
		}
		
		private function pauseVideo(e:MouseEvent):void {
			video.pause();
		}
		
		private function playVideo(e:MouseEvent):void {
			video.resume();
			_isPlaying = true;
		}
		
		private function updateControls(e:Event):void {
			try {
				controls.playedPercent = video.time / video.duration;
				
				if (controls.dragging) return;
				
				controls.videoDuration = video.duration;
				controls.bufferPercent = (video.time + video.currentBuffer) / video.duration;
				
				var mouseOver:Boolean = video.hitTestPoint(stage.mouseX, stage.mouseY);
				if (mouseOver && controlsAvailable == 0) showControls(true);
				if ((!mouseOver) && (controlsAvailable == 1)) showControls(false);
			} catch (e:Error) {
				trace("Caught error in VideoPlayer.updateControls()");
			}
		}
		
		private function controlVideo(e:Event):void {
			video.seek(controls.playedPercent * video.duration);
		}
		
		public function close():void {
			removeEventListener(Event.ENTER_FRAME, updateControls);
			controls.removeEventListener(Event.CHANGE, controlVideo);
			video.close();
			showControls(false);
			
			video.visible = false;
			hideLoading();
		}
		
		public function dispose():void {
			TweenMax.killTweensOf(this);
			TweenMax.killChildTweensOf(this);
			
			video.removeEventListener(VideoStreamEvent.BUFFER_EMPTY, showLoading);
			video.removeEventListener(VideoStreamEvent.BUFFER_FULL, hideLoading);
			video.removeEventListener(VideoStreamEvent.BUFFER_FLUSH, hideLoading);
			video.removeEventListener(VideoStreamEvent.VIDEO_ENDED, endFullscreen);
			video.removeEventListener(VideoStreamEvent.VIDEO_ENDED, videoEnded);
			
			controls.playButton.removeEventListener(MouseEvent.CLICK, playVideo);
			controls.pauseButton.removeEventListener(MouseEvent.CLICK, pauseVideo);
			controls.removeEventListener(MouseEvent.CLICK, toggleFullscreen);
			controls.removeEventListener(Event.CHANGE, controlVideo);
			
			stage.removeEventListener(FullScreenEvent.FULL_SCREEN, toggleFullscreen);
			startButton.removeEventListener(MouseEvent.CLICK, startButtonClick);
			removeEventListener(Event.ENTER_FRAME, updateControls);
			
			video.dispose();
			video = null;
			controls.dispose();
			controls = null;
			while (numChildren > 0) removeChildAt(0);
		}
		
		override public function get height():Number { return video.height; }
		
		override public function set height(value:Number):void {
			video.height = value;
			controls.y = value - (controls.height * controlsAvailable) - _controlsMarginY + 1;
			startButton.y = (value - startButton.height) * 0.5;
			loadingIndicator.y = (value - loadingIndicator.height) * 0.5;
		}
		
		override public function get width():Number { return video.width; }
		
		override public function set width(value:Number):void {
			video.width = value;
			controls.width = value;
			startButton.x = (value - startButton.width) * 0.5
			loadingIndicator.x = (value - loadingIndicator.width) * 0.5;
		}
		
		public function get controlsMarginY():Number { return _controlsMarginY; }
		
		public function set controlsMarginY(value:Number):void {
			_controlsMarginY = value;
			height = video.height; // calls setter
		}
		
		public function get controlsMarginX():Number { return controls.margins; }
		
		public function set controlsMarginX(value:Number):void {
			controls.margins = value;
		}
		
		public function get isPlaying():Boolean {
			return _isPlaying;
		}
		
	}
}