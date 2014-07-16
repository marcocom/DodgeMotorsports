package com.dodgems.grid.gadget {
	import com.barliesque.utils.applyText;
	import com.barliesque.utils.unescapeHTML;
	import com.dodgems.grid.GridPage;
	import com.greensock.easing.Quint;
	import com.greensock.TweenMax;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class InfoBox extends BaseGadget {
		
		// on-stage
		public var background:MovieClip;
		public var swipe:MovieClip;
		public var scrollMask:MovieClip;
		public var sideline:MovieClip;
		public var scrollbar:Scrollbar;
		public var title:TextField;
		public var body:TextField;
		public var linkBar1:MovieClip;
		public var linkBar2:MovieClip;
		public var linkMessage1:TextField;
		public var linkButton1:SimpleButton;
		public var linkMessage2:TextField;
		public var linkButton2:SimpleButton;
		public var shareBar:MovieClip;
		// on-stage: shareBar
		public var shareButton:SimpleButton;
		public var closeButton:SimpleButton;
		
		private var link1:String;
		private var link2:String;
		private var linkType1:String;
		private var linkType2:String;
		private var bodyStyle:StyleSheet;
		
		private var info:XML;
		private var links:int;
		
		
		[Event(name="InfoBox.CLOSE", type="flash.events.Event")]
		static public const CLOSE:String = "InfoBox.CLOSE";
		
		
		public function InfoBox() {
			shareButton = shareBar["shareButton"];
			closeButton = shareBar["closeButton"];
			
			linkButton1.addEventListener(MouseEvent.CLICK, openLink, false, 0, true);
			linkButton2.addEventListener(MouseEvent.CLICK, openLink, false, 0, true);
			closeButton.addEventListener(MouseEvent.CLICK, unlockCell, false, 0, true);
			shareButton.addEventListener(MouseEvent.CLICK, visitFacebook, false, 0, true);
			
			body.addEventListener(TextEvent.LINK, textLink, false, 0, true);
			
			bodyStyle = new StyleSheet();
			bodyStyle.setStyle("a:hover", { color:'#FFCCBB', textDecoration:'none' } );
			bodyStyle.setStyle("a:link", { textDecoration:'underline', fontWeight: 'bold' } );
			body.styleSheet = bodyStyle;
			
			scrollbar.setTarget(body, scrollMask);
		}
		
		private function textLink(e:TextEvent):void {
			if (e.text.indexOf("/") < 0) {
				// No forward slashes? ...must be an item navigation
				page.doAction("item", [e.text]);
			} else {
				// If it contains slashes then this is a branch navigation
				page.doAction("branch", [e.text]);
			}
		}
		
		
		override public function show(params:Array, xml:XML):void {
			//
			//  Set up the InfoBox to show specified data
			//
			if (xml.name() == "info" || xml.name() == "news") {
				info = xml;
			} else {
				info = xml.info[0];
				if (info.title == undefined) info.title = xml.title;
			}
			
			mask = page.currentCell.gadgetMask;
			
			// Hide all links until they're turned on...
			links = 0;
			linkBar1.visible = linkBar2.visible = false;
			linkMessage1.visible = linkMessage2.visible = false;
			linkButton1.visible = linkButton2.visible = false;
			shareBar.visible = !page.rolloverController.enabled;
			
			// Is the share bar visible?
			if (shareBar.visible) {
				++links;
				linkBar1.visible = true;
			}
			
			// Is there a link?
			if (info.link != undefined) {
				++links;
				addLink(info.link[0], links);
				
				// Is there a second link?
				if (info.link.length() > 1 && links < 2) {
					++links;
					addLink(info.link[1], links);
				}
			}
			
			applyText(unescapeHTML(info.title).toUpperCase(), title);
			applyText(unescapeHTML(info.body) + "<BR/>", body);
			body.cacheAsBitmap = true;
			
			y = page.currentCell.y - 1.0;
			setHeight(page.currentCell.height);
			body.height = scrollMask.height;
			body.mask = scrollMask;
			visible = true;
			
			scrollbar.position = 0;
			scrollbar.wheelArea = page.currentCell;
			
			var side:String = params[0];
			if (side == "left") {
				x = page.currentCell.x - width;
				TweenMax.to(this, 0.8, { alpha: 1.0, x: page.currentCell.x - 1, ease: Quint.easeOut, onComplete: resizeInfoBox } );
			} else {
				x = page.currentCell.x + page.currentCell.width;
				TweenMax.to(this, 0.8, { alpha: 1.0, x: page.currentCell.x + page.currentCell.width - width + 1, ease: Quint.easeOut, onComplete: resizeInfoBox } );
			}
		}
		
		private function unlockCell(e:MouseEvent):void {
			page.unlockGrid();
		}
		
		private function resizeInfoBox():void {
			setHeight(page.currentCell.height);
		}
		
		
		override public function hide():void {
			body.cacheAsBitmap = true;
			super.hide();
		}
		
		
		private function addLink(xml:XML, linkNum):void {
			applyText(xml.toString(), this["linkMessage" + linkNum]);
			this["linkBar" + linkNum].visible = true;
			this["linkMessage" + linkNum].visible = true;
			this["linkButton" + linkNum].visible = true;
			if (xml.@url != undefined) {
				this["link" + linkNum] = xml.@url;
				this["linkType" + linkNum] = "url";
			} else if (xml.@branch != undefined) {
				this["link" + linkNum] = xml.@branch;
				this["linkType" + linkNum] = "branch";
			} else if (xml.@item != undefined) {
				this["link" + linkNum] = xml.@item;
				this["linkType" + linkNum] = "item";
			} else {
				var type:String = xml.attributes()[0].name();
				this["linkType" + linkNum] = type;
				this["link" + linkNum] = xml.@[type];
			}
		}
		
		
		private function setHeight(value:Number):void {
			background.height = value + 20;		// 390 + 20
			swipe.height = background.height;
			
			linkBar1.y = value - 32;			// 390 - 32
			linkMessage1.y = linkBar1.y + 1;	// 
			linkButton1.y = linkBar1.y + 3;
			
			shareBar.y = linkBar1.y;
			
			linkBar2.y = value - 64;
			linkMessage2.y = linkBar2.y + 1;
			linkButton2.y = linkBar2.y + 3;
			
			var titleHeight:Number = Math.min(title.height, title.textHeight);
			scrollMask.y = body.y = titleHeight + title.y + 5;
			
			switch (links) {
				case 0:		scrollMask.height = value - (body.y + 22);	break;
				case 1:		scrollMask.height = value - (body.y + 40);	break;
				case 2:		scrollMask.height = value - (body.y + 80);	break;
			}
			
			var bh:Number = Math.min(body.textHeight, scrollMask.height);
			sideline.height = bh + body.y;
			scrollbar.y = body.y;
			scrollbar.position = 0;
			scrollbar.height = bh;
			scrollbar.visible = body.textHeight > scrollMask.height;
		}
		
		override public function set height(value:Number):void {
			setHeight(value);
		}
		
		override public function get width():Number { return super.width; }
		override public function set width(value:Number):void {
			// not permitted
		}
		
		
		private function openLink(e:MouseEvent):void {
			
			var linkNum:int = String(e.target.name).split("linkButton")[1];
			page.doAction(this["linkType" + linkNum], [this["link" + linkNum]]);
		}
		
		
		/**
		 * Prepare for Garbage Collection
		 */
		override public function dispose():void {
			scrollbar.dispose();
			scrollbar = null;
			
			//  REMOVE EVENT LISTENERS
			shareButton.removeEventListener(MouseEvent.CLICK, visitFacebook);
			closeButton.removeEventListener(MouseEvent.CLICK, unlockCell);
			linkButton1.removeEventListener(MouseEvent.CLICK, openLink);
			linkButton2.removeEventListener(MouseEvent.CLICK, openLink);
			body.removeEventListener(TextEvent.LINK, textLink);
			
			//  REMOVE CHILDREN FROM DISPLAY LIST
			while (numChildren > 0) removeChildAt(0);
			
			//  NULL OUT VARIABLES
			closeButton = null;
			shareButton = null;
			linkButton1 = null;
			linkButton2 = null;
			shareBar = null;
			body = null;
			
			super.dispose();
		}
		
		override public function get dragging():Boolean {
			return scrollbar.dragging;
		}
		
	}
}