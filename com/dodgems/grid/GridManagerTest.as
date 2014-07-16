package com.dodgems.grid {
	import com.greensock.easing.Quint;
	import com.greensock.TweenMax;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class GridManagerTest extends MovieClip {
		
		var gridManager:GridManager;
		private var cellNo:int = -1;
		
		public function GridManagerTest() {
			gridManager = new GridManager(6);
			gridManager.init(this);
			
			for (var i:int = 1; i <= 9; i++) {
				var cell:DisplayObject = this["cell" + i];
				cell.addEventListener(MouseEvent.MOUSE_OUT, restoreGrid, false, 0, true);
				cell.addEventListener(MouseEvent.MOUSE_OVER, changeCell, false, 0, true);
			}
		}
		
		private function restoreGrid(e:MouseEvent):void {
			gridManager.restoreGrid();
			update();
		}
		
		private function changeCell(m:MouseEvent):void {
			var cell:DisplayObject = m.target as DisplayObject;
			cellNo = int(cell.name.substr(4));
			cell.alpha = 0.4;
			gridManager.expandCell(cell, 160, 160);
			update();
		}
		
		private function update():void {
			for (var i:int = 0; i < numChildren; i++) {
				var cell:DisplayObject = getChildAt(i);
				if (gridManager.isCell(cell)) {
					var rect:Rectangle = gridManager.getCellRect(cell);
					TweenMax.to(cell, 1, { x:rect.x, y:rect.y, width:rect.width, height:rect.height, ease:Quint.easeInOut } );
					if (int(cell.name.substr(4)) == cellNo) trace(rect) else cell.alpha = 1.0;
				}
			}
		}
		
	}
}