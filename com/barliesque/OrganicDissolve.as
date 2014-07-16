package com.barliesque {
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.events.Event;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class OrganicDissolve extends ShaderFilter {
		
		[Embed(source="pbj/OrganicDissolve.txt", mimeType="application/octet-stream")] 
		static internal var ShaderClass:Class; 
		
		// Parameters
		public var map:BitmapData;
		public var dissolve:Number;
		public var invert:Boolean;
		public var softEdge:Number;
		public var mapScaleX:Number;
		public var mapScaleY:Number;
		public var mapChannel:int;
		
		
		static public const MAP_CHANNEL_R:int = 1;
		static public const MAP_CHANNEL_G:int = 2;
		static public const MAP_CHANNEL_B:int = 3;
		static public const MAP_CHANNEL_A:int = 4;
		
		public function OrganicDissolve(map:BitmapData, dissolve:Number = 1.0, invert:Boolean = false, softEdge:Number = 0.15, mapScaleX:Number = 1.0, mapScaleY:Number = 1.0, mapChannel:int = 1) {
			this.map = map;
			this.dissolve = dissolve;
			this.invert = invert;
			this.softEdge = softEdge;
			this.mapScaleX = mapScaleX;
			this.mapScaleY = mapScaleY;
			this.mapChannel = mapChannel;
			
			shader = new Shader(new ShaderClass());
			update();
		}
		
		public function update(...ignore):void {
			shader.data.map.input = map;
			shader.data.invert.value = [invert ? 1 : 0];
			shader.data.softEdge.value = [softEdge];
			shader.data.dissolve.value = [dissolve];
			shader.data.mapScaleX.value = [mapScaleX];
			shader.data.mapScaleY.value = [mapScaleY];
			shader.data.mapChannel.value = [mapChannel];
		}
		
	}
}