package com.dodgems.grid.gadget {
	import com.greensock.easing.Quint;
	import com.greensock.TweenMax;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import org.libspark.ui.SWFWheel;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class Scrollbar extends MovieClip {
		
		// on-stage
		public var scrollBack:SimpleButton;
		public var scrollForward:SimpleButton;
		public var puck:MovieClip;
		public var track:SimpleButton;
		
		private var backRect:Rectangle;
		private var foreRect:Rectangle;
		private var puckRect:Rectangle;
		private var trackBotToForeTop:Number;
		private var puckMin:Number;
		private var puckMax:Number;
		
		private var _position:Number = 0;
		private var _dragging:Boolean = false;
		
		public var content:DisplayObject;
		public var contentArea:DisplayObject;
		public var wheelArea:DisplayObject;
		
		private var dragRect:Rectangle;
		private var scrollingBack:Boolean;
		private var targetPosition:Number = -1;
		
		
		
		public function Scrollbar() {
			init();
		}
		
		public function setTarget(content:DisplayObject, contentArea:DisplayObject, wheelArea:DisplayObject = null):void {
			this.content = content;
			this.contentArea = contentArea;
			this.wheelArea = (wheelArea == null) ? contentArea : wheelArea;
			if (content != null) {
				activate();
			} else {
				deactivate();
			}
		}
		
		
		private function init():void {
			backRect = scrollBack.getRect(this);
			foreRect = scrollForward.getRect(this);
			puckRect = puck.getRect(this);
			var puckYoffset:Number = puckRect.top - puck.y;
			puckMin = puckRect.top - puckYoffset;
			puckMax = foreRect.top - puckRect.height - (puckRect.top - backRect.bottom) - puckYoffset;
			dragRect = new Rectangle(puck.x, puckMin, 0, puckMax - puckMin);
			ButtonEvent.makeButton(puck);
			
			var trackRect:Rectangle = track.getRect(this);
			trackBotToForeTop = trackRect.bottom - foreRect.top;
		}
		
		
		public function activate(...ignore):void {
			scrollBack.addEventListener(MouseEvent.MOUSE_DOWN, beginScrolling, false, 0, true);
			scrollBack.addEventListener(MouseEvent.MOUSE_UP, stopScrolling, false, 0, true);
			scrollBack.addEventListener(MouseEvent.MOUSE_OUT, stopScrolling, false, 0, true);
			
			scrollForward.addEventListener(MouseEvent.MOUSE_DOWN, beginScrolling, false, 0, true);
			scrollForward.addEventListener(MouseEvent.MOUSE_UP, stopScrolling, false, 0, true);
			scrollForward.addEventListener(MouseEvent.MOUSE_OUT, stopScrolling, false, 0, true);
			
			track.addEventListener(MouseEvent.MOUSE_DOWN, trackScroll, false, 0, true);
			
			puck.addEventListener(ButtonEvent.DRAG, beginDrag, false, 0, true);
			puck.addEventListener(ButtonEvent.RELEASE, endDrag, false, 0, true);
			puck.addEventListener(ButtonEvent.RELEASE_OUTSIDE, endDrag, false, 0, true);
			
			(stage) ? added() : addEventListener(Event.ADDED_TO_STAGE, added, false, 0, true);
		}
		
		private function added(e:Event = null):void {
			if (e) removeEventListener(Event.ADDED_TO_STAGE, added);
			SWFWheel.initialize(stage);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, wheelScroll, false, 0, true);
		}
		
		
		public function deactivate():void {
			scrollBack.removeEventListener(MouseEvent.MOUSE_DOWN, beginScrolling);
			scrollBack.removeEventListener(MouseEvent.MOUSE_UP, stopScrolling);
			scrollBack.removeEventListener(MouseEvent.MOUSE_OUT, stopScrolling);
			
			scrollForward.removeEventListener(MouseEvent.MOUSE_DOWN, beginScrolling);
			scrollForward.removeEventListener(MouseEvent.MOUSE_UP, stopScrolling);
			scrollForward.removeEventListener(MouseEvent.MOUSE_OUT, stopScrolling);
			
			track.removeEventListener(MouseEvent.MOUSE_DOWN, trackScroll);
			
			puck.removeEventListener(ButtonEvent.DRAG, beginDrag);
			puck.removeEventListener(ButtonEvent.RELEASE, endDrag);
			puck.removeEventListener(ButtonEvent.RELEASE_OUTSIDE, endDrag);
			if (_dragging) endDrag();
			
			stage.removeEventListener(MouseEvent.MOUSE_WHEEL, wheelScroll);
		}
		
		//----------------------------------------------------
		
		private function wheelScroll(e:MouseEvent):void {
			// Over the content area or the scrollbar?
			var overContent:Boolean = wheelArea.hitTestPoint(stage.mouseX, stage.mouseY);
			var overScroll:Boolean = hitTestPoint(stage.mouseX, stage.mouseY);
			if (!(overContent || overScroll)) return;
			
			scrollTo(_position - ((e.delta * 50) / content.height));
		}
		
		//----------------------------------------------------
		
		private function beginScrolling(e:MouseEvent):void {
			scrollingBack = (e.target == scrollBack);
			addEventListener(Event.ENTER_FRAME, keepScrolling, false, 0, true);
		}
		
		private function keepScrolling(e:Event):void {
			scrollTo(_position - ((scrollingBack ? 50 : -50) / content.height));
		}
		
		private function stopScrolling(e:MouseEvent):void {
			removeEventListener(Event.ENTER_FRAME, keepScrolling);
		}
		
		//----------------------------------------------------
		
		private function trackScroll(e:MouseEvent):void {
			scrollTo((mouseY - track.y) / track.height);
		}
		
		//----------------------------------------------------
		
		private function beginDrag(e:MouseEvent):void {
			if (!_dragging) {
				_dragging = true;
				puck.startDrag(false, dragRect);
			}
			
			scrollTo((puck.y - puckMin) / (puckMax - puckMin), false);	// calls setter
		}
		
		private function endDrag(e:MouseEvent = null):void {
			puck.stopDrag();
			_dragging = false;
		}
		
		//----------------------------------------------------
		
		private function scrollTo(pos:Number, tweenPuck:Boolean = true):void {
			if (tweenPuck) {
				TweenMax.to(this, 0.8, { position: pos, ease: Quint.easeOut } );
			} else {
				targetPosition = pos;
				TweenMax.to(this, 0.8, { position: pos, ease: Quint.easeOut, onUpdate:puckOnTarget } );
			}
		}
		
		private function puckOnTarget():void {
			puck.y = puckMin + (puckMax - puckMin) * targetPosition;
		}
		
		private function updateScroll(...ignore):void {
			var contentHeight:Number = content.height - contentArea.height + 50;
			if (contentHeight < 0) contentHeight = 0;
			content.y = contentArea.y - (contentHeight * _position);
			if (!_dragging) {
				puck.y = puckMin + (puckMax - puckMin) * _position;
			}
		}
		
		public function update():void {
			height = this.height;
		}
		
		
		public function dispose():void {
			deactivate();
			while (numChildren > 0) removeChildAt(0);
		}
		
		//----------------------------------------------------
		//  ACTIVE PROPERTIES
		//----------------------------------------------------
		
		public function get position():Number { return _position; }
		
		public function set position(value:Number):void {
			if (value < 0) value = 0;
			if (value > 1) value = 1;
			_position = value;
			updateScroll();
		}
		
		override public function get height():Number { return super.height; }
		
		override public function set height(value:Number):void {
			foreRect = scrollForward.getRect(this);
			var foreYoffset:Number = foreRect.top - scrollForward.y;
			scrollForward.y = value - foreRect.height - foreYoffset;
			
			track.height = value - track.y - foreRect.height + trackBotToForeTop;
			
			var puckYoffset:Number = puckRect.top - puck.y;
			puckMax = foreRect.top - puckRect.height - (puckRect.top - backRect.bottom) - puckYoffset;
			dragRect.height = puckMax - puckMin;
		}
		
		//----------------------------------------------------
		//  READ-ONLY PROPERTIES
		//----------------------------------------------------
		
		public function get dragging():Boolean { return _dragging; }
		
		override public function get width():Number { return super.width; }
		override public function set width(value:Number):void {
			// Can not be changed
		}
		
	}
}