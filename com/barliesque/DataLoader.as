package com.barliesque {
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.events.Event;
	import flash.net.URLVariables;
	
	/**
	 * This is a modified version of the class DataLoader, 
	 * which is a part of the MORFsite framework by David Barlia.
	 */
	
	public class DataLoader {
		
		public var url:String;				// The url to be loaded
		public var onDone:Function;		// Call this function when data finishes loading

		private var request:URLRequest;
		private var loader:URLLoader;
		public var xml:XML;
		public var list:XMLList;
		private var _loaded:Boolean;
		private var traceStatus:Boolean;
		
		
		/**
		 * Load an XML data file
		 * @param	url				The URL of an XML file to load
		 * @param	onDone			(optional) A function to call when loading has completed
		 * @param	allowCaching	Set to true to allow file to be reloaded from the cache (default: FALSE)
		 */
		public function DataLoader(url:String = null, onDone:Function = null, allowCaching:Boolean = false, traceStatus:Boolean = false) {
			this.traceStatus = traceStatus;
			if (url != null) load(url, onDone, allowCaching);
		}
		
		
		/**
		 * Load an XML data file
		 * @param	url				The URL of an XML file to load
		 * @param	onDone			(optional) A function to call when loading has completed
		 * @param	allowCaching	Set to true to allow file to be reloaded from the cache (default: FALSE)
		 */
		public function load(url:String, onDone:Function = null, allowCaching:Boolean = false):void {
			// Not the first time?
			if (loader != null) release();
			
			// Request the file for loading
			this.url = absoluteURL(url);
			request = new URLRequest(this.url);
			
			// As long as we're not running offline...
			if (new LocalConnection().domain != "localhost" && !allowCaching) {
				// Stop the file from being read from the cache
				var variables:URLVariables = new URLVariables();  
				variables.nocache = new Date().getTime(); 
				request.data = variables;
			}
			
			// Create the loader
			loader = new URLLoader();
			
			// Register to be notified of loading completion and errors
			loader.addEventListener(Event.COMPLETE, dataLoaded, false, 0, true);
			loader.addEventListener(IOErrorEvent.IO_ERROR, catchIOError, false, 0, true);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatus, false, 0, true);
			
			// When the data is fully loaded, we'll call this function.
			this.onDone = onDone;
			
			// Load the XML!
			_loaded = false;
			loader.load(request);
		}
		
		private function httpStatus(e:HTTPStatusEvent):void {
			if (traceStatus) trace(request.url, " - Status code: " + e.status);
		}
		
		private function catchIOError(e:IOErrorEvent):void {
			trace(request.url, " - Error caught: " + e.type + " - " + loader.bytesLoaded + " / " + loader.bytesTotal + " bytes loaded");
			if (loader.data != null) dataLoaded();
		}
		
		
		private function dataLoaded(...ignore):void {
			loader.removeEventListener(Event.COMPLETE, dataLoaded);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, catchIOError);
			loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatus);
			
			list = XMLList(loader.data).copy();
			xml = list[0];
			
			_loaded = true;
			if (onDone != null) onDone(this);
			loader.close();
		}
		
		
		public function get loaded():Boolean { return _loaded; }
		
		
		public function release(...ignore):void {
			try {
				loader.close();
			} catch (e:Error) { }
			loader = null;
			request = null;
			xml = null;
			_loaded = false;
		}
		
		
		public function absoluteURL(relativeURL:String):String {
			if (relativeURL.substr(0, 7) != "http://" && ExternalInterface.available) {
				var urlPath:String = ExternalInterface.call("window.location.href.toString");
				if (urlPath) {
					var baseURL:String = urlPath.substr(0, urlPath.lastIndexOf("/") + 1);
					if (baseURL.search("#")) {
						baseURL = baseURL.substr(0, baseURL.lastIndexOf("#"));
					}
					
					return baseURL + relativeURL;
				}
			}
			return relativeURL;
		}		
		
	}
}