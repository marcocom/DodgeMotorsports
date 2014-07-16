package com.dodgems.grid {
	import com.barliesque.DataLoader;
	import com.barliesque.DataTree;
	import com.barliesque.ImageLoader;
	import com.barliesque.utils.findXML;
	import com.dodgems.grid.gadget.BaseGadget;
	import com.dodgems.grid.gadget.InfoBox;
	import com.dodgems.grid.gadget.SlideShow;
	import com.dodgems.grid.gadget.VideoGallery;
	import com.gaiaframework.api.Gaia;
	import com.gaiaframework.events.GaiaSWFAddressEvent;
	import com.gaiaframework.templates.AbstractPage;
	import com.greensock.easing.Back;
	import com.greensock.easing.Quad;
	import com.greensock.easing.Quint;
	import com.greensock.TweenMax;
	import fl.motion.easing.Linear;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class GridPage extends AbstractPage {
		
		// on-stage
		public var navPlaceholder:MovieClip;
		public var homeLink:SimpleButton;			// optional
		public var foreground:MovieClip;
		public var background:MovieClip;
		public var infoBox:InfoBox;
		public var slideshow:SlideShow;
		public var videoGallery:VideoGallery;
		public var caption:CellCaption;
		public var headline:MovieClip;
		public var loadingIndicator:MovieClip;
		//
		// up to 20 cells on stage... add more if needed
		//
		public var cell1:GridCell;
		public var cell2:GridCell;
		public var cell3:GridCell;
		public var cell4:GridCell;
		public var cell5:GridCell;
		public var cell6:GridCell;
		public var cell7:GridCell;
		public var cell8:GridCell;
		public var cell9:GridCell;
		public var cell10:GridCell;
		public var cell11:GridCell;
		public var cell12:GridCell;
		public var cell13:GridCell;
		public var cell14:GridCell;
		public var cell15:GridCell;
		public var cell16:GridCell;
		public var cell17:GridCell;
		public var cell18:GridCell;
		public var cell19:GridCell;
		public var cell20:GridCell;
		public var cellTitle1:MovieClip;
		public var cellTitle2:MovieClip;
		public var cellTitle3:MovieClip;
		public var cellTitle4:MovieClip;
		public var cellTitle5:MovieClip;
		public var cellTitle6:MovieClip;
		public var cellTitle7:MovieClip;
		public var cellTitle8:MovieClip;
		public var cellTitle9:MovieClip;
		public var cellTitle10:MovieClip;
		public var cellTitle11:MovieClip;
		public var cellTitle12:MovieClip;
		public var cellTitle13:MovieClip;
		public var cellTitle14:MovieClip;
		public var cellTitle15:MovieClip;
		public var cellTitle16:MovieClip;
		public var cellTitle17:MovieClip;
		public var cellTitle18:MovieClip;
		public var cellTitle19:MovieClip;
		public var cellTitle20:MovieClip;
		
		//  Page-specific
		protected var totalCells:int;
		protected var dataXML:XML;
		
		public var rolloverController:RolloverController;
		
		protected var _currentItem:String;
		protected var gridManager:GridManager;	
		protected var _currentCell:GridCell;
		protected var _currentCellNum:int;
		protected var activeGadget:BaseGadget;
		protected var justLoaded:Boolean = true;
		private var motionBlurs:Array = [];
		private var blurFilterIndex:int;
		private var navPage:MovieClip;
		
		private const GRID_SPACING:Number = 10;
		private var cellsLoaded:Boolean;
		private var _currentCellID:String;
		
		public var deeplink:Array;
		public var deepDeepLinkID:String;
		
		
		public function GridPage(totalCells:int) {
			super();
			
			if (Gaia.api) {
				alpha = 0;
				navPlaceholder.visible = false;
				navPage = Gaia.api.getPage("index/nav").content;
			}
			
			if (loadingIndicator) {
				loadingIndicator.alpha = 0;
				loadingIndicator.mouseEnabled = loadingIndicator.mouseChildren = false;
			}
			this.totalCells = totalCells;
			
			//
			//  Are we testing the page outside Gaia?
			//
			if (!Gaia.api) {
				test();
			}
		}
		
		
		protected function test():void { }
		
		
		private var tree:DataTree;
		
		override public function transitionIn():void {
			if (loadingIndicator) {
				var addTo:DisplayObjectContainer = this.parent;
				while (!(addTo is Sprite)) addTo = addTo.parent;
				addTo.addChild(loadingIndicator);
				TweenMax.to(loadingIndicator, 0.6, { delay: 0.5, alpha: 1, overwrite: 1 } );
			}
			init();
			tree = new DataTree(dataXML, continueTransitionIn);
		}
		
		protected function continueTransitionIn(xml:XML):void {
			dataXML = xml;
			if (loadingIndicator) TweenMax.to(loadingIndicator, 0.6, { delay: 0.5, alpha: 0, overwrite: 1 } );
			
			var currentDeeplink:String = Gaia.api.getDeeplink();
			onDeeplink(new GaiaSWFAddressEvent(GaiaSWFAddressEvent.DEEPLINK, false, false, currentDeeplink));
			
			if (navPage) navPage["showNav"](true);
			TweenMax.to(this, 0.3, { alpha:1 } );
			super.transitionIn();
		}
		
		
		protected function init():void {
			//
			//  Set up grid & rollovers
			//
			gridManager = new GridManager(GRID_SPACING);
			gridManager.init(this, "cell");
			
			rolloverController = new RolloverController();
			rolloverController.enabled = false;
			
			for (var i:int = 1; i <= totalCells; i++) {
				var cell:GridCell = this["cell" + i] as GridCell;
				if (cell == null) throw new Error("cell" + i + ":GridCell not found!  totalCells: " + totalCells);
				
				rolloverController.addRollover(cell);
				cell.addEventListener(MouseEvent.MOUSE_DOWN, clickAction, false, 0, true);
				cell.x = ((i % 2) == 1) ? 2000 : -2000;
				cell.width = 5;
				var blur:BlurFilter = new BlurFilter(50, 0, 1);
				motionBlurs.push(blur);
				blurFilterIndex = cell.filters.push(blur);
				
				cell.addEventListener(ImageLoader.IMAGE_LOADED, cellLoaded, false, 0, true);
			}
			
			rolloverController.hitDoctor.addEventListener(HitDoctorEvent.NEW_PATIENT, mouseOver, false, 1, true);
			rolloverController.hitDoctor.addEventListener(HitDoctorEvent.NO_PATIENT, mouseOut, false, 1, true);
			
			foreground.mouseEnabled = false;
			
			if (homeLink) homeLink.addEventListener(MouseEvent.CLICK, goHome, false, 0, true);
			showHomeLink(false, true);
			
			if (infoBox == null) throw new Error("Can't find infoBox!");
			infoBox.visible = false;
			
			if (foreground == null) throw new Error("Can't find foreground!");
			foreground.mouseChildren = foreground.mouseEnabled = false;
			
			if (headline) TweenMax.to(headline, 1.5, { y: 0, ease: Quint.easeInOut } );
			
			if (navPage) navPage["showNav"](true);  // Sprinkled here and there just to be on the safe side
		}
		
		
		private function showHomeLink(show:Boolean, immediate:Boolean = false):void {
			if (homeLink) {
				homeLink.enabled = show;
				if (immediate) {
					homeLink.alpha = (show ? 1.0 : 0.0);
				} else {
					TweenMax.to(homeLink, 0.6, { alpha: (show ? 1.0 : 0.0) } );
				}
			}
		}
		
		
		protected function goHome(e:Event):void {
			doAction("home");
		}
		
		
		private function mouseOut(e:HitDoctorEvent):void {
			if (activeGadget != null) {
				if (activeGadget.dragging) {
					e.ignored = true;
					return;
				}
			}
			if (!rolloverController.enabled) return;
			unlockGrid();
		}
		
		
		public function unlockGrid():void {
			gridManager.restoreGrid();
			tweenGrid(false,false);
			if (_currentCell != null) _currentCell.showTitleBar(true);
			_currentCell = null;
			_currentCellID = "";
			rolloverController.enabled = true;
			rolloverController.rollOut();
		}
		
		public function lockGrid():void {
			rolloverController.enabled = false;
		}
		
		
		private function mouseOver(e:HitDoctorEvent):void {
			if (activeGadget != null) {
				if (activeGadget["dragging"]) {
					e.ignored = true;
					return;
				}
			}
			if (!rolloverController.enabled || justLoaded) return;
			if (_currentCell != null) _currentCell.showTitleBar(true);
			
			var newCell:GridCell = e.patient as GridCell;
			if (newCell == _currentCell) return; //False alarm
			_currentCell = newCell;
			_currentCellID = newCell.data.@id;
			_currentCellNum = int(_currentCell.name.substr(4));
			activateCell();
				
			if (Gaia.api) navPage["playSound"]("gridOverSFX");
			if (navPage) navPage["showNav"](true);  // Sprinkled here and there just to be on the safe side
		}
		
		
		public function activateCell(doHover:Boolean = true, hideGadget:Boolean = true):void {
			//
			//  Make sure the image isn't bigger than the grid!
			//
			var safeScale:Number = 1.0;
			if (_currentCell) {
				if (_currentCell.imageWidth > gridManager.gridWidth || _currentCell.imageHeight > gridManager.gridHeight) {
					safeScale = Math.min(gridManager.gridWidth / _currentCell.imageWidth, gridManager.gridHeight / _currentCell.imageHeight);
				}
				
				gridManager.expandCell(_currentCell, _currentCell.imageWidth * safeScale, _currentCell.imageHeight * safeScale);
			}
			tweenGrid(doHover, false, hideGadget);
		}
		
		
		private function tweenGrid(doHoverAction:Boolean = true, immediate:Boolean = false, hideGadget:Boolean = true):void {
			//if (Gaia.api && justLoaded) navPage["playSound"]("flyInSFX");
			if (activeGadget && hideGadget) activeGadget.hide();
			
			for (var i:int = 1; i <= totalCells; i++) {
				var cell:GridCell = this["cell" + i] as GridCell;
				var rect:Rectangle = gridManager.getCellRect(cell);
				var delaySecs:Number;
				if (immediate) {
					cell.x = rect.x;
					cell.y = rect.y;
					cell.width = rect.width;
					cell.height = rect.height;
				} else {
					if (justLoaded) {
						
						delaySecs = 0.5 + (1.0 * (i / totalCells));
						TweenMax.to(motionBlurs[i - 1], 0.7, { blurX: 0, delay: delaySecs, ease: Quint.easeIn } );
						if (i == totalCells) {
							TweenMax.to(cell, 0.75, { x:rect.x, y:rect.y, width:rect.width, height:rect.height, 
														ease: Back.easeOut, delay: delaySecs, onUpdate: updateFlyIn, onComplete: flyInDone } );
						} else {
							TweenMax.to(cell, 0.75, { x:rect.x, y:rect.y, width:rect.width, height:rect.height, 
														ease: Back.easeOut, delay: delaySecs, onUpdate: updateFlyIn } );
						}
					} else {
						delaySecs = 0;
						if (hideGadget) caption.hide();
						if (doHoverAction && i == _currentCellNum) {
							TweenMax.to(cell, 1.2, { x:rect.x, y:rect.y, width:rect.width, height:rect.height, 
														ease: Quint.easeInOut, delay: delaySecs,
														onUpdate: resizeGadget, onUpdateParams: [!hideGadget], onComplete: hoverAction } );
						} else {
							TweenMax.to(cell, 1.2, { x:rect.x, y:rect.y, width:rect.width, height:rect.height, 
														ease: Quint.easeInOut, delay: delaySecs, 
														onUpdate: resizeGadget, onUpdateParams: [!hideGadget] } );
						}
					}
				}
			}
		}
		
		
		private function resizeGadget(alignCaption:Boolean):void {
			if (activeGadget) activeGadget.resize();
			if (alignCaption) caption.align();
		}
		
		
		private function updateFlyIn():void {
			try {
			for (var i:int = 1; i <= totalCells; i++) {
				var cell:GridCell = this["cell" + i] as GridCell;
				if (cell != null) {
					var filters:Array = cell.filters;
					if (blurFilterIndex < filters.length && blurFilterIndex >= 0) {
						filters[blurFilterIndex] = motionBlurs[i - 1];
					}
					cell.filters = filters;
				}
			}
			} catch (err:Error) { }
		}
		
		
		private function flyInDone():void {
			transitionInComplete();
			justLoaded = false;
			rolloverController.enabled = true;
			motionBlurs = null;
			getDeepDeeplink();
			if (navPage) navPage["showNav"](true);
		}
		
		
		private function getDeepDeeplink():void {
			//
			//  DEEP-DEEP-LINK?
			//
			if (deeplink != null) {
				if (deeplink.length > 1) {
					deepDeepLinkID = (deeplink.length > 2) ? deeplink[2] : null;
					lockActivateCell(deeplink[1]);
				}
			}
		}
		
		
		private function lockActivateCell(cellID:String):void {
			
			var num:int = cellByID(cellID);
			
			if (num == -1) {
				deepDeepLinkID = null;
				return;
			}
			
			_currentCellNum = num;
			_currentCellID = cellID;
			_currentCell = this["cell" + num];
			
			rolloverController.doRollover(_currentCell);
			rolloverController.enabled = false;
			activateCell();
		}

		
		private function cellByID(id:String):int {
//			var cells:XMLList = dataXML.item.(@id == _currentItem).cell;
			var cells:XMLList = findXML(dataXML.item, findItem)[0].cell;
			for each(var cell:XML in cells) {
				
				if (cell.@id == id) return cell.@num;
			}
			return -1;
		}
		
		
		override public function onDeeplink(event:GaiaSWFAddressEvent):void {
			deeplink = event.deeplink.substr(1).split("/");
			var item:String = deeplink[0];
			updateGrid(item);
		}
		
		private function findItem(xml:XML):Boolean {
			if (_currentItem == "") {
				if (xml.@id == undefined) return true;
			}
			return (xml.@id == _currentItem);
		}
		
		
		protected function updateGrid(item:String):void {
			
			//
			//
			//  Reload all cells
			//
			_currentItem = item;
			
			var xml:XML = findXML(dataXML.item, findItem)[0];
			
			if (xml == null) return;
			
			for each (var cell:XML in xml.cell) {
				var rollover:GridCell = this["cell" + cell.@num] as GridCell;
				if (rollover) {
					rollover.init(cell);
					rollover.buttonMode = (cell.@click != undefined);
				}
			}
			
			//  Lock up the grid while loading
			//
			cellsLoaded = false;
			gridManager.restoreGrid();
			if (!justLoaded) tweenGrid(false);
			rolloverController.rollOut();
			rolloverController.enabled = false;
			showHomeLink(false);
			
			if (loadingIndicator) TweenMax.to(loadingIndicator, 0.6, { delay: 0.5, alpha: 1, overwrite: 1 } );
			
			//
			//  After each cell loads, an event takes us to cellLoaded()
			//  (See init() for the addEventListener)
			//
		}
		
		
		private function cellLoaded(e:Event):void {
			//
			//  If any image is still loading...
			//
			if (!cellsLoaded) {
				for (var i:int = 1; i <= totalCells; i++) {
					var cell:GridCell = this["cell" + i] as GridCell;
					if (!cell.loaded) return;	// ...then get outta here.
				}
				cellsLoaded = true;
			} else {
				// Stop the following from executing more than once!
				return;
			}
			
			//
			//  Restore the grid!
			//
			tweenGrid(false);
			_currentCell = null;
			_currentCellID = "";
			if (!justLoaded) rolloverController.enabled = true;
			rolloverController.rollOut();
			if (loadingIndicator) TweenMax.to(loadingIndicator, 0.4, { alpha: 0, overwrite: 1 } );
			showHomeLink(_currentItem != "");
		}
		
		
		private function hoverAction():void {
			var xml:XML = findXML(dataXML.item, findItem)[0].cell.(@num == _currentCellNum)[0];
			if (xml == null) return;
			var hover:String = xml.@hover;
			if (hover != "" && hover != null) {
				var parse:Array = hover.split(":");
				var action:String = parse[0];
				var params:String = parse[1];
				doAction(action, params ? params.split(",") : null);
			}
			if (xml.caption != undefined) doAction("caption", [xml.caption[0]]);
		}
		
		
		private function clickAction(e:MouseEvent):void {
			if (!rolloverController.enabled) return;
			var xml:XML = itemXML();
			var click:String = xml.@click;
			if (click == "" && click != null) return;
			var parse:Array = click.split(":");
			var action:String = parse[0];
			var params:String = parse[1];
			doAction(action, params ? params.split(",") : null);
		}
		
		protected function itemXML():XML {
//			var xml:XML = dataXML.item.(@id == _currentItem)[0].cell.(@num == _currentCellNum)[0];
			var xml:XML = findXML(dataXML.item, findItem)[0].cell.(@num == _currentCellNum)[0];
			return xml;
		}
		
		public function doAction(action:String, params:Array = null):void {
			if (params == null) params = [];
			action = action.toLowerCase();
			var xml:XML = itemXML();
			switch (action) {
				case "info":
					// Show info box
					if (xml.info == undefined) trace("XML ERROR!  <info> not found in <item id=\"" + _currentItem + "\"><cell num=\"" + _currentCellNum + "\">");
					infoBox.show(params, xml);
					activeGadget = infoBox;
					_currentCell.showTitleBar(false);
					caption.text = "";
					break;
				case "caption":
					// Show a caption in the cell
					showCaption(params);
					break;
				case "slides":
					// Show slide controls & caption
					if (xml.slide != undefined) {
						slideshow.show(params, xml);
						activeGadget = slideshow;
					}
					break;
				case "video":
					if (xml.video != undefined) {
						videoGallery.show(params, xml);
						activeGadget = videoGallery;
						_currentCell.showTitleBar(false);
					}
					break;
				case "home":
					// Back to home
					if (Gaia.api) {
						Gaia.api.goto(Gaia.api.getCurrentBranch());	// This sends us to onDeeplink()
					} else {
						updateGrid("");
					}
					break;
				case "item":
					// Go to the specified item
					if (Gaia.api) {
						Gaia.api.goto(Gaia.api.getCurrentBranch() + "/" + params[0]);	// This sends us to onDeeplink()
					} else {
						updateGrid(params[0]);
					}
					break;
				case "branch":
					// Go to the specified branch
					var branch:String = params[0];
					if (branch.substr(0, 1) == "/") branch = branch.substr(1);
//					if (branch.substr(0, 1) != "/") branch = "/" + branch;
					//if (Gaia.api) {
						//trace("BRANCH: " + branch);
						//Gaia.api.goto(branch);
					//}
					if (navPage) {
						navPage["siteNavCall"](branch);
					} else {
						trace("NAVIGATE TO BRANCH:  " + branch);
					}
					break;
				case "url":
					navigateToURL(new URLRequest("http://" + params[0]), "_blank");
					break;
				case "http":
					navigateToURL(new URLRequest("http:" + params[0]), "_blank");
					break;
				case "https":
					navigateToURL(new URLRequest("https:" + params[0]), "_blank");
					break;
				case "mailto":
					navigateToURL(new URLRequest("mailto:" + params[0]), "_blank");
					break;
			}
		}
		
		protected function showCaption(params:Array):void {
			caption.text = params[0];
		}
		
		public function changeCaption(newCaption:String, permanent:Boolean = true):void {
			caption.text = newCaption;
			if (permanent) itemXML().caption[0] = <caption>{newCaption}</caption>;
		}
		
		public function changeImage(img:String, pos:String):void {
			_currentCell.addEventListener(ImageLoader.IMAGE_IN_FULL, cellReloaded, false, 0, true);
			_currentCell.changeImage(img, pos);
		}
		
		private function cellReloaded(e:Event):void {
			var cell:GridCell = e.target as GridCell;
			cell.removeEventListener(ImageLoader.IMAGE_IN_FULL, cellReloaded);
			if (_currentCell) activateCell(false, false);
		}
		
		protected function disableRollover(gadget:BaseGadget):void {
			activeGadget = gadget;
			activeGadget.addEventListener("close", enableRollover, false, 0, true);
			rolloverController.enabled = false;
		}
		
		protected function enableRollover(e:Event):void {
			activeGadget.removeEventListener("close", enableRollover);
			rolloverController.enabled = true;
		}

		
		override public function transitionOut():void {
			super.transitionOut();
			TweenMax.killAll(true);
			if (navPage) navPage["showNav"](false);
			TweenMax.to(this, 0.3, {alpha:0, onComplete:transitionOutComplete});
		}
		
		override public function transitionOutComplete():void {
			dispose();
			super.transitionOutComplete();
		}
		
		protected function dispose():void {
			//
			//  Prepare for Garbage Collection
			//
			
			// REMOVE EVENT LISTENERS
			for (var i:int = 1; i <= totalCells; i++) {
				var cell:GridCell = this["cell" + i] as GridCell;
				cell.removeEventListener(MouseEvent.MOUSE_DOWN, clickAction);
				cell.removeEventListener(ImageLoader.IMAGE_LOADED, cellLoaded);
			}
			
			rolloverController.hitDoctor.removeEventListener(HitDoctorEvent.NEW_PATIENT, mouseOver);
			rolloverController.hitDoctor.removeEventListener(HitDoctorEvent.NO_PATIENT, mouseOut);
			
			if (homeLink) homeLink.removeEventListener(MouseEvent.CLICK, goHome);
			
			if (activeGadget != null) {
				if (rolloverController.enabled == false) {
					activeGadget.removeEventListener("close", enableRollover);
				}
				//activeGadget.dispose();
				activeGadget = null;
			}
			
			// TELL OBJECTS THAT LINK TO THIS TO DISPOSE
			
			TweenMax.killChildTweensOf(this, true);
			TweenMax.killChildTweensOf(this);
			rolloverController.dispose();
			gridManager.dispose();
			infoBox.dispose();
			slideshow.dispose();
			
			// NULL OUT MEMBER PROPERTIES
			
			rolloverController = null;
			gridManager = null;
			dataXML = null;
			_currentCell = null;
			_currentCellID = "";
			activeGadget = null;
			motionBlurs = null;
			navPage = null;
			infoBox = null;
			slideshow = null;
			
			while (numChildren > 0) removeChildAt(0);
		}
		
		public function get currentCell():GridCell { return _currentCell; }
		
		public function get currentCellID():String { return _currentCellID; }
		
		public function get currentCellNum():int { return _currentCellNum; }
		
		public function get currentItem():String { return _currentItem; }
		
	}
}
