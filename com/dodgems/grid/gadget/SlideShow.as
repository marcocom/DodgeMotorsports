package com.dodgems.grid.gadget {
	import com.dodgems.grid.GridCell;
	import com.dodgems.grid.GridPage;
	import com.gaiaframework.api.Gaia;
	import com.greensock.easing.Quint;
	import com.greensock.TweenMax;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class SlideShow extends BaseGadget {
		
		// on-stage
		public var thumbSelector:ThumbSelector;
		public var buttons:MovieClip;
		// on-stage: inside "buttons"
		private var shareButton:SimpleButton;
		private var closeButton:SimpleButton;
		
		private var data:XML;
		private var myCell:GridCell;
		
		public function SlideShow() {
			thumbSelector.addEventListener(ThumbEvent.SELECTION, slideSelected, false, 0, true);
			
			shareButton = buttons["shareButton"];
			closeButton = buttons["closeButton"];
			buttons.visible = false;
			
			closeButton.addEventListener(MouseEvent.CLICK, unlockGrid, false, 0, true);
			shareButton.addEventListener(MouseEvent.CLICK, visitFacebook, false, 0, true);
		}
		
		private function slideSelected(e:ThumbEvent):void {
			var slideXML:XML = e.thumb.userData;
			page.changeImage(slideXML.@img, slideXML.@pos);
			
			var title:String = slideXML.valueOf();
			page.changeCaption(title);
			
			myCell.titleBar.alpha = 0;
			myCell.titleBar.visible = false;
			lockGrid();
			
			setDeepLink(slideXML.@id);
		}
		
		override public function show(params:Array, xml:XML):void {
			
			var defaultImage:String = xml.@img;
			var defaultCaption:String = (xml.caption == undefined) ? "" : xml.caption;
			//
			//  Make sure the default image is listed as a <slide>
			//
			if (xml.slide.(@img == defaultImage) == undefined) {
				var slides:XMLList = xml.slide;
				delete xml.slide;
				xml.slide = <slide id="" img={defaultImage}>{defaultCaption}</slide>;
				xml.slide += slides;
			}
			
			myCell = page.currentCell;
			myCell.showTitleBar(false);
			
			mask = page.currentCell.gadgetMask;
			y = page.currentCell.y;
			height = page.currentCell.height;
			
			if (page.deepDeepLinkID == null) {
				thumbSelector.show(xml, "slide", page.currentCell.imageURL);
				setDeepLink();
			} else {
				thumbSelector.show(xml, "slide", page.deepDeepLinkID);
				thumbSelector.selectThumb(null, true, false);
				setDeepLink(page.deepDeepLinkID);
				page.deepDeepLinkID = null;
			}
			buttons.visible = !page.rolloverController.enabled;
			
			x = page.currentCell.x - width;
			TweenMax.to(this, 0.8, { alpha: 1.0, x: page.currentCell.x - 1, ease: Quint.easeOut } );
			
			visible = true;
		}
		
		override public function resize():void {
			if (page.currentCell != null) {
				height = page.currentCell.height;
				x = page.currentCell.x;
				y = page.currentCell.y;
				buttons.x = page.currentCell.width - (buttons.width - 3);
			}
		}
		
		
		private function lockGrid():void {
			buttons.visible = true;
			page.lockGrid();
		}
		
		private function unlockGrid(e:Event):void {
			buttons.visible = false;
			page.unlockGrid();
		}
		
		override public function hide():void {
			if (myCell.titleBar) {
				if (!myCell.titleBar.visible) {
					myCell.titleBar.alpha = 0;
					myCell.titleBar.visible = true;
				}
			}
			thumbSelector.remove();
			super.hide();
		}
		
		override public function dispose():void {
			thumbSelector.removeEventListener(ThumbEvent.SELECTION, slideSelected);
			closeButton.removeEventListener(MouseEvent.CLICK, unlockGrid);
			shareButton.addEventListener(MouseEvent.CLICK, visitFacebook);
			super.dispose();
		}
		
		override public function set height(value:Number):void {
			thumbSelector.height = value;
			buttons.y = value - (buttons.height - 3);
		}
		
	}
}