package com.dodgems.grid.gadget {
	import com.barliesque.utils.replaceAll;
	import com.dodgems.grid.GridPage;
	import com.gaiaframework.api.Gaia;
	import com.greensock.TweenMax;
	import flash.display.MovieClip;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class BaseGadget extends MovieClip {
		
		protected var page:GridPage;
		public var deepLink:String;
//		public var title:String = "";
		
		public function BaseGadget() {
			visible = false;
			page = parent as GridPage;
		}
		
		public function get dragging():Boolean {
			return false;
		}
		
		public function show(params:Array, xml:XML):void {
			
		}
		
		public function resize():void {
			
		}
		
		public function hide():void {
			TweenMax.to(this, 0.5, { alpha: 0, onComplete: hideGadget } );
		}
		
		private function hideGadget():void {
			visible = false;
		}
		
		
		protected function setDeepLink(id:String = ""):void {
			var url:String;
			if (Gaia.api) {
				url = Gaia.api.getBaseURL() + "/#" + Gaia.api.getValue();
				var deep:String = Gaia.api.getDeeplink();
				url = url.substr(0, url.length - deep.length);
				url += "/" + page.currentItem + "/" + page.currentCellID + "/" + id;
			} else {
				url = "http://www.dodgemotorsports.com";
			}
			deepLink = url;
trace("DEEPLINK:  " + deepLink);
		}
		
		protected function visitFacebook(...ignore):void {
			var rootURL:String = "http://www.facebook.com/share.php?u=";	// t=" + escape(title) + "&
			navigateToURL(new URLRequest(rootURL + replaceAll(deepLink, "#/", "")), "_blank");
		}
		
		
		public function dispose():void {
			page = null;
			while (numChildren > 0) removeChildAt(0);
		}
		
	}
}