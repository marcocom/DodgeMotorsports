package com.barliesque {
	import com.barliesque.DataLoader;
	import com.greensock.TweenLite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	/**
	 * ...
	 * @author David Barlia
	 */
	public class DataTree extends EventDispatcher {
		
		private var loader:DataLoader;
		private var subLoader:DataLoader;
		//private var oldLoader:DataLoader;
		private var onDone:Function;
		private var _complete:Boolean = false;
		public var xml:XML;
		
		static public const DATA_LOADED:String = "DataTree.DATA_LOADED";
		
		public function DataTree(dataXML:XML = null, onDone:Function = null) {
			this.onDone = onDone;
			if (dataXML != null) expandData(dataXML);
		}
		
		public function load(url:String = null, onDone:Function = null):void {
			this.onDone = onDone;
			loader = new DataLoader(url, expandDataFile);
		}
		
		private function expandDataFile(loader:DataLoader):void {
			expandData(loader.xml);
		}
		
		public function expandData(dataXML:XML):void {
			xml = dataXML;
			loadSubFile();
		}
		
		private function loadSubFile():void {
			//
			//  Find an <xml/> to load
			//
			var xmlTag:XMLList = xml..xml;
			if (xmlTag.length() > 0) {
				if (subLoader) subLoader.release();
				
//				oldLoader = subLoader;
				subLoader = new DataLoader(xmlTag[0].@file, insertData);
			} else {
				//  DONE!
				//trace("TREE HAS LOADED!");
				
				_complete = true;
				if (onDone != null) onDone(xml);
				dispatchEvent(new Event(DATA_LOADED));
				if (subLoader) subLoader.release();
			}
		}
		
		private function insertData(loader:DataLoader):void {
			
			var xmlTag:XMLList = xml..xml;
			if (loader.xml == null) {
				delete xmlTag[0];
			} else {
				if (loader.list.length() == 1) {
					if (loader.list.name() == "xml") {
						loader.list = loader.list[0].*;
					}
				}
				if (loader.list.length() > 0) {
					xmlTag[0] = loader.list.copy();
				} else {
					delete xmlTag[0];
				}
			}
			
			// Look for another sub-file
			TweenLite.delayedCall(0.01, loadSubFile);
//			loadSubFile();
		}
		
		public function get complete():Boolean { return _complete; }
		
	}
}