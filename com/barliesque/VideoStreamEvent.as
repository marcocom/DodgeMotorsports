package com.barliesque {
	import flash.events.Event;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class VideoStreamEvent extends Event {
		
		public static const BUFFER_FULL:String =	"VideoStreamEvent.BUFFER_FULL";
		public static const BUFFER_FLUSH:String =	"VideoStreamEvent.BUFFER_FLUSH";
		public static const BUFFER_EMPTY:String =	"VideoStreamEvent.BUFFER_EMPTY";
		public static const VIDEO_ENDED:String =	"VideoStreamEvent.VIDEO_ENDED";
		public static const META_DATA:String =		"VideoStreamEvent.META_DATA";
		public static const CUE_POINT:String =		"VideoStreamEvent.CUE_POINT";
		public static const ERROR:String =			"VideoStreamEvent.ERROR";
		public static const READY:String =			"VideoStreamEvent.READY";
		public static const SEEK_POINT:String =		"VideoStreamEvent.SEEK_POINT";
		
		public var data:*;
		public var stream:VideoStream;
		
		public function VideoStreamEvent(type:String, stream:VideoStream, data:* = null, bubbles:Boolean = false, cancelable:Boolean = false) { 
			super(type, bubbles, cancelable);
			this.data = data;
			this.stream = stream;
		} 
		
		public override function clone():Event {
			return new VideoStreamEvent(type, stream, data, bubbles, cancelable);
		} 
		
		public override function toString():String { 
			return formatToString("VideoEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}