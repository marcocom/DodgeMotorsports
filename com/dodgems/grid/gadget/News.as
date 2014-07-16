package com.dodgems.grid.gadget {
	import com.asual.swfaddress.SWFAddress;
	import com.barliesque.utils.applyText;
	import com.dodgems.grid.GridPage;
	import com.greensock.easing.Quint;
	import com.greensock.TweenMax;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class News extends BaseGadget {
		
		// on-stage
		public var scrollMask:MovieClip;
		public var scrollbar:Scrollbar;
		public var swipe:MovieClip;
		public var background:MovieClip;
		public var headlineArea:MovieClip;
		public var closeButton:SimpleButton;
		public var closeMessage:TextField;
		
		private var headlines:MovieClip;
		private var info:XML;
		
		
		public function News() {
		}
		
		private function unlockCell(e:MouseEvent):void {
			closeButton.removeEventListener(MouseEvent.CLICK, unlockCell);
			page.unlockGrid();
		}
		
		
		override public function show(params:Array, xml:XML):void {
			var newsXML:XMLList = xml.news;
			var side:String = params[0];
			
			page.currentCell.showTitleBar(false);
			
			if (headlines != null) removeChild(headlines);
			headlines = new MovieClip();
			headlines.x = scrollMask.x;
			headlines.y = scrollMask.y;
			headlines.mask = scrollMask;
			headlines.cacheAsBitmap = true;
			addChild(headlines);
			
			for each(var item:XML in newsXML) {
				var headline:NewsHeadline = new NewsHeadline();
				if (item.title != undefined) headline.setData(item, page.currentCellID + "/" + item.@id, side);
				headline.y = headlines.height;
				headlines.addChild(headline);
				headline.addEventListener(MouseEvent.CLICK, newsLink, false, 0, true);
				
				//  WAIT A SECOND!  Is this a deep-deep-link?
				if (page.deepDeepLinkID != null) {
					if (item.@id == page.deepDeepLinkID) {
						gotoNewsLink(headline);
						page.deepDeepLinkID = null;
						
						// Don't bother continuing to build the headlines view
						// since we're about to open directly to the news item itself
						return;
					}
				}
			}
			
			
			scrollbar.setTarget(headlines, scrollMask, page.currentCell);
			height = page.currentCell.height;
			y = page.currentCell.y - 1;
			mask = page.currentCell.gadgetMask;
			visible = true;
			
			closeMessage.mouseEnabled = false;
			closeButton.visible = !page.rolloverController.enabled;
			closeMessage.visible = !page.rolloverController.enabled;
			if (!page.rolloverController.enabled) {
				closeButton.addEventListener(MouseEvent.CLICK, unlockCell, false, 0, true);
			}
			
			if (side == "left") {
				x = page.currentCell.x - width;
				TweenMax.to(this, 0.8, { alpha: 1.0, x: page.currentCell.x - 1, ease: Quint.easeOut, onComplete: resizeNews} );
			} else {
				x = page.currentCell.x + page.currentCell.width;
				TweenMax.to(this, 0.8, { alpha: 1.0, x: page.currentCell.x + page.currentCell.width - width + 1, ease: Quint.easeOut, onComplete: resizeNews } );
			}
		}
		
		
		private function resizeNews():void {
			height = page.currentCell.height;
		}
		
		
		private function newsLink(e:MouseEvent):void {
			gotoNewsLink(e.target.parent as NewsHeadline);
		}
		
		private function gotoNewsLink(headline:NewsHeadline):void {
			page.lockGrid();
			page.doAction("newsItem", [headline.id, headline.data]);
			hide();
			setDeepLink(headline.id.split("/")[1]);
			page.infoBox.deepLink = deepLink;
		}
		
		override public function get height():Number { return super.height; }
		
		override public function set height(value:Number):void {
			background.height = swipe.height = value + 10;
			scrollMask.height = headlineArea.height = scrollbar.height = value - 70;
			scrollbar.visible = scrollbar.enabled = (headlines.height > scrollMask.height);
		}
		
		override public function get dragging():Boolean {
			return scrollbar.dragging;
		}
		
		override public function dispose():void {
			scrollbar.dispose();
			scrollbar = null;
			
			while (numChildren > 0) removeChildAt(0);
			
			super.dispose();
		}
		
	}
}