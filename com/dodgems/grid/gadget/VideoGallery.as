package com.dodgems.grid.gadget {
	import com.barliesque.VideoCue;
	import com.barliesque.VideoStream;
	import com.barliesque.VideoStreamEvent;
	import com.dodgems.grid.GridCell;
	import com.dodgems.grid.GridPage;
	import com.greensock.easing.Quint;
	import com.greensock.TweenMax;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class VideoGallery extends BaseGadget {
		
		public var thumbSelector:ThumbSelector;
		public var videoPlayer:VideoPlayer;
		public var closeButton:MovieClip;
		
		private var data:XML;
		private var myCell:GridCell;
		private var videoXML:XML;
		
		
		public function VideoGallery() {
			//videoPlayer.visible = false;
			closeButton.visible = false;
			thumbSelector.addEventListener(ThumbEvent.SELECTION, videoSelected, false, 0, true);
			videoPlayer.video.addEventListener(VideoStreamEvent.READY, videoReady, false, 0, true);
			videoPlayer.video.addEventListener(VideoStreamEvent.CUE_POINT, videoCue, false, 0, true);
			videoPlayer.controls.addEventListener(Event.CHANGE, eraseCaption, false, 0, true);
			videoPlayer.video.addEventListener(VideoStreamEvent.VIDEO_ENDED, nextVideo, false, 0, true);
			videoPlayer.startButton.addEventListener(MouseEvent.CLICK, startPlaying, false, 0, true);
			videoPlayer.addEventListener(Event.RESIZE, matchThumbToControls, false, 0, true);
			videoPlayer.controls.addEventListener("share", visitFacebook, false, 0, true);
		}
		
		private function matchThumbToControls(...ignore):void {
			height = videoPlayer.height;  // calls setter
		}
		
		private function startPlaying(e:MouseEvent):void {
			thumbSelector.selectFirst();
		}
		
		private function nextVideo(...ignore):void {
			thumbSelector.selectNext();
		}
		
		private function eraseCaption(...ignore):void {
			//title = "";
			page.caption.hide();
		}
		
		private function videoSelected(e:ThumbEvent):void {
			videoXML = e.thumb.userData;
			videoPlayer.open(videoXML.@url, true, videoXML.caption);
			
			//title = videoXML.title;
			
			lockGrid();
			eraseCaption();
			setDeepLink(videoXML.@id);
		}
		
		private function lockGrid():void {
			closeButton.visible = true;
			closeButton.addEventListener(MouseEvent.CLICK, unlockGrid, false, 0, true);
			page.lockGrid();
		}
		
		private function unlockGrid(e:Event):void {
			closeButton.visible = false;
			closeButton.removeEventListener(MouseEvent.CLICK, unlockGrid);
			page.unlockGrid();
		}
		
		private function videoReady(e:VideoStreamEvent):void {
			// Resize cell to maximize video size -- The grid manager will restrict its size properly
			myCell.sizeOverride(videoPlayer.video.videoWidth * 2.0, videoPlayer.video.videoHeight * 2.0);
			page.activateCell(false, false);
		}
		
		private function videoCue(e:VideoStreamEvent):void {
			var cue:VideoCue = e.data as VideoCue;
			if (cue.parameters.caption == "") {
				eraseCaption();
			} else {
				page.changeCaption(cue.parameters.caption, false);
			}
		}
		
		override public function dispose():void {
			myCell.sizeOverride();
			thumbSelector.removeEventListener(ThumbEvent.SELECTION, videoSelected);
			thumbSelector.dispose();
			thumbSelector = null;
			videoPlayer.video.removeEventListener(VideoStreamEvent.READY, videoReady);
			videoPlayer.video.removeEventListener(VideoStreamEvent.CUE_POINT, videoCue);
			videoPlayer.removeEventListener(Event.RESIZE, matchThumbToControls);
			videoPlayer.controls.removeEventListener("share", visitFacebook);
			videoPlayer.dispose();
			videoPlayer = null;
			super.dispose();
		}
		
		
		override public function show(params:Array, xml:XML):void {
			myCell = page.currentCell;
			mask = page.currentCell.gadgetMask;
			//y = page.currentCell.y;
			//height = page.currentCell.height;
			resize();
			
			thumbSelector.show(xml, "video", page.deepDeepLinkID);
			if (page.deepDeepLinkID == null) {
				thumbSelector.selectFirst(false);
			}
			thumbSelector.visible = (thumbSelector.thumbCount > 1);
			
			videoPlayer.controls.togglePlayPause(true);
			videoPlayer.showControls(false);
			
			x = page.currentCell.x - thumbSelector.width;
			TweenMax.to(this, 0.8, { alpha: 1.0, x: page.currentCell.x, ease: Quint.easeOut } );
			
			if (page.deepDeepLinkID == null) {
				// Steal the big START BUTTON
				videoPlayer.startButton.visible = true;
				addChildAt(videoPlayer.startButton, getChildIndex(videoPlayer));
				setDeepLink();
			} else {
				// Open the deep-deep link immediately
				videoPlayer.startButton.visible = false;
				thumbSelector.selectThumb();
				setDeepLink(page.deepDeepLinkID);
				page.deepDeepLinkID = null;
			}
			
			visible = true;
		}
		
		
		override public function hide():void {
			myCell.sizeOverride();
			thumbSelector.remove();
			videoPlayer.close();
			eraseCaption();
			//title = "";
			super.hide();
		}
		
		override public function resize():void {
			if (page.currentCell != null) {
				height = page.currentCell.height;
				width = page.currentCell.width;
				x = page.currentCell.x;
				y = page.currentCell.y;
			}
		}
		
		override public function get width():Number { return videoPlayer.width; }
		
		override public function set width(value:Number):void {
			videoPlayer.width = value;
			videoPlayer.x = 0;
			closeButton.x = value - closeButton.width + 1;
		}
		
		override public function get height():Number { return videoPlayer.height; }
		
		override public function set height(value:Number):void {
			videoPlayer.height = value;
			thumbSelector.height = videoPlayer.controls.y;
		}
		
		override public function get dragging():Boolean { return videoPlayer.controls.dragging; }
		
	}
}
