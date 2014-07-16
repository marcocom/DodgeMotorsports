package com.dodgems.grid.gadget {
	import com.barliesque.ImageLoader;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class ThumbEvent extends Event {
		
		public var thumb:ImageLoader;
		
		static public const SELECTION:String = "ThumbEvent.SELECTION";
		
		public function ThumbEvent(type:String, thumb:ImageLoader) { 
			super(type, false, false);
			this.thumb = thumb;
		} 
		
		public override function clone():Event { 
			return new ThumbEvent(type, thumb);
		} 
		
		public override function toString():String { 
			return formatToString("ThumbEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
}