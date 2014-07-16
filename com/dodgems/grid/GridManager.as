package com.dodgems.grid {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class GridManager {
		
		private var cell:Dictionary;
		
		private var hGuide:Array;
		private var vGuide:Array;
		private var hGuidePos:Array;
		private var vGuidePos:Array;
		private var hExpand:Number = 0;
		private var vExpand:Number = 0;
		private var expandGuideL:int = 0;
		private var expandGuideR:int = 0;
		private var expandGuideT:int = 0;
		private var expandGuideB:int = 0;
		
		private const SNAP_TOLERANCE:int = 8;
		
		public var spacing:Number;
		
		private var rect:Rectangle;
		
		
		
		public function GridManager(spacing:Number = 8) {
			this.spacing = spacing;
		}
		
		/**
		 * Initialize the grid controller
		 * @param	parentClip		Container where all cell objects will be found
		 * @param	prefix			Cells must have instance names beginning with this prefix
		 */
		public function init(parentClip:DisplayObjectContainer, prefix:String = "cell"):void {
			//
			//  Find all the cells in the grid by their instance name
			//	And set guides based on their bounding rectangles
			//
			cell = new Dictionary(true);
			hGuide = new Array();
			vGuide = new Array();
			
			for (var i:int = 0; i < parentClip.numChildren; i++) {
				var child:DisplayObject = parentClip.getChildAt(i);
				if (child.name.toLowerCase().substr(0, prefix.length) == prefix.toLowerCase()) {
					//
					//  Add the cell to the grid, and it's rectangle to our guides
					//
					cell[child] = { };
					addGuide(vGuide, child.getRect(parentClip).top);
					addGuide(vGuide, child.getRect(parentClip).bottom);
					addGuide(hGuide, child.getRect(parentClip).left);
					addGuide(hGuide, child.getRect(parentClip).right);
				}
			}
			
			//
			//  Which guides will each cell be bound by?  (Snap to guides)
			//
			for (var key:Object in cell) {
				child = key as DisplayObject;
				cell[child].top = getNearestGuide(vGuide, child.getRect(parentClip).top);
				cell[child].bottom = getNearestGuide(vGuide, child.getRect(parentClip).bottom);
				cell[child].left = getNearestGuide(hGuide, child.getRect(parentClip).left);
				cell[child].right = getNearestGuide(hGuide, child.getRect(parentClip).right);
			}
			
			//
			//  Save the bounds of the whole grid (includes outer margin of spacing*0.5 pixels)
			//
			rect = new Rectangle(hGuide[0], vGuide[0], hGuide[hGuide.length - 1] - hGuide[0], vGuide[vGuide.length - 1] - vGuide[0]);
			
			//
			//  Re-evaluate guides as percentages
			//
			for (i = 0; i < hGuide.length; i++) hGuide[i] = (hGuide[i] - rect.left) / rect.width;
			for (i = 0; i < vGuide.length; i++) vGuide[i] = (vGuide[i] - rect.top) / rect.height;
			
			recalculateGuides();
		}
		
		private function addGuide(guides:Array, value:Number):void {
			//
			//  Don't add a guide that already exists (within SNAP_TOLERANCE pixels)
			//
			for (var i:int = 0; i < guides.length; i++) {
				if (Math.abs(guides[i] - value) <= SNAP_TOLERANCE) return;
			}
			//
			//  Add the guide and keep the array sorted
			//
			guides.push(value);
			guides.sort(Array.NUMERIC);
		}
		
		
		private function getNearestGuide(guides:Array, value:Number):int {
			for (var i:int = 0; i < guides.length; i++) {
				if (Math.abs(guides[i] - value) <= SNAP_TOLERANCE) return i;
			}
			
			throw new Error("This error is totally impossible.");
			return -1;	// JUST NOT POSSIBLE
		}
		
		//------------------------------------------------------
		
		public function isCell(cellClip:DisplayObject):Boolean {
			return (cell[cellClip] != null);
		}
		
		
		public function expandCell(cellClip:DisplayObject, width:Number, height:Number):void {
			if (!isCell(cellClip)) throw new Error("Object is not part of the grid!");
			
			expandGuideL = cell[cellClip].left;
			expandGuideT = cell[cellClip].top;
			expandGuideR = cell[cellClip].right;
			expandGuideB = cell[cellClip].bottom;
			
			var defaultWidth:Number = (hGuide[cell[cellClip].right] - hGuide[cell[cellClip].left]) * rect.width - spacing;
			var defaultHeight:Number = (vGuide[cell[cellClip].bottom] - vGuide[cell[cellClip].top]) * rect.height - spacing;
			
			//
			//  Don't allow a cell to expand the grid beyond its original dimensions!
			//
			var safeScale:Number = 1.0;
			//trace("Expand to: " + int(width) + " x " + int(height) + "    ...grid: " + int(rect.width) + " x " + int(rect.height));
			
			var hgap:Number = spacing * hGuide.length;
			var vgap:Number = spacing * vGuide.length;
			if (width > rect.width - hgap || height > rect.height - vgap) safeScale = Math.min((rect.width - hgap) / width, (rect.height - vgap) / height);
			
			hExpand = (width * safeScale) - defaultWidth;
			vExpand = (height * safeScale) - defaultHeight;
			
			//
			//  If a cell spans the full height/width of the grid, then that dimension may not change
			//
			if (expandGuideL == 0 && expandGuideR == hGuide.length - 1) hExpand = expandGuideL = expandGuideR = 0;
			if (expandGuideT == 0 && expandGuideB == vGuide.length - 1) vExpand = expandGuideT = expandGuideB = 0;
			
			
			recalculateGuides();
		}
		
		
		public function restoreGrid():void {
			hExpand = vExpand = 0;
			expandGuideL = expandGuideT = expandGuideR = expandGuideB = 0;
			recalculateGuides();
		}
		
		//------------------------------------------------------
		
		private function recalculateGuides():void {
			//
			//  Recalculate all guide positions, based on current cell expansion
			//
			hGuidePos = [];
			vGuidePos = [];
			var i:int;
			for (i = 0; i < hGuide.length; i++)	hGuidePos[i] = guidePos(false,	i);
			for (i = 0; i < vGuide.length; i++)	vGuidePos[i] = guidePos(true,	i);
			
			//
			//  Never allow any guide to be on the wrong side of the guides on either side of it
			//
			for (i = 1;  i < hGuide.length - 1; i++) {
				hGuidePos[i] = Math.max(hGuidePos[i], hGuidePos[i-1]);
				hGuidePos[i] = Math.min(hGuidePos[i], hGuidePos[i+1]);
			}
			for (i = 1;  i < vGuide.length - 1; i++) {
				vGuidePos[i] = Math.max(vGuidePos[i], vGuidePos[i-1]);
				vGuidePos[i] = Math.min(vGuidePos[i], vGuidePos[i+1]);
			}
			
		}
		
		private function interp(i:int, li:int, hi:int, betweenL:Number, betweenH:Number):Number {
			var spanned:int = hi - li;
			var partSpan:Number = i - li;
			var range:Number = betweenH - betweenL;
			
			var result:Number = betweenL + (partSpan * (range / (spanned + 1)));
			return result;
		}
		
		
		//------------------------------------------------------
		
		public function getCellRect(cellClip:DisplayObject):Rectangle {
			if (!isCell(cellClip)) throw new Error("Object is not part of the grid!");
			
			var cellRect:Rectangle = new Rectangle();
			var gap:Number = spacing * 0.5;
			
			cellRect.top = getCellEdge(vGuidePos, cell[cellClip].top, gap);
			cellRect.left = getCellEdge(hGuidePos, cell[cellClip].left, gap);
			cellRect.right = getCellEdge(hGuidePos, cell[cellClip].right, -gap);
			cellRect.bottom = getCellEdge(vGuidePos, cell[cellClip].bottom, -gap);
			
			//cellRect.top = vGuidePos[cell[cellClip].top] + gap;
			//cellRect.left = hGuidePos[cell[cellClip].left] + gap;
			//cellRect.right = hGuidePos[cell[cellClip].right] - gap;
			//cellRect.bottom = vGuidePos[cell[cellClip].bottom] - gap;
			
			return cellRect;
		}
		
		private function getCellEdge(guides:Array, index:int, gap:Number):Number {
			var edge:Number = guides[index];
			if (index > 0 && index < (guides.length - 1)) edge += gap;
			return edge;
		}
		
		private function guidePos(vertical:Boolean, thisGuide:int):Number {
			var guides:Array = vertical ? vGuide : hGuide;
			
			// Outer guides are always at the borders of the grid
			if (thisGuide == 0) return (vertical ? rect.top : rect.left);
			if (thisGuide == guides.length - 1) return (vertical ? rect.bottom : rect.right);
			
			var pos:Number = (guides[thisGuide] * (vertical ? rect.height : rect.width)) + (vertical ? rect.top : rect.left);
			
			//
			//  Now adjust guide position to allow for an expanded cell
			//
			var expandGuide1:int = vertical ? expandGuideT : expandGuideL;
			var expandGuide2:int = vertical ? expandGuideB : expandGuideR;
			var span:int = expandGuide2 - expandGuide1 - 1;
			var moving:int = guides.length - 2 - span;
			var expansion:Number = (vertical ? vExpand : hExpand) / moving;
			
			// The total expansion divided by the number of guides that will be adjusted
			
			var index:int;
			if (thisGuide <= expandGuide1) {
				// Guide is behind expanding cell
				pos -= expansion * thisGuide;
				
			} else if (thisGuide >= expandGuide2) {
				// Guide is ahead of expanding cell
				pos += expansion * (guides.length - 1 - thisGuide);
			} else {
				// Guide is spanned by expanding cell
				pos -= expansion * (thisGuide - 1);
				expansion = (vertical ? vExpand : hExpand) / (span + 1);
				pos += expansion * (thisGuide - expandGuide1);
			}
			
			return pos;
		}
		
		public function get gridWidth():Number {
			return rect.width;
		}
		
		public function get gridHeight():Number {
			return rect.height;
		}
		
		//------------------------------------------------------
		
		public function dispose():void {
			for (var key:Object in cell) delete cell[key];
			cell = null;
		}
		
		//------------------------------------------------------
	}
}