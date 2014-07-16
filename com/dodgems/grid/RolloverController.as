package com.dodgems.grid {
	import com.dodgems.grid.HitDoctorEvent;
	import com.greensock.easing.Quad;
	import com.greensock.OverwriteManager;
	import com.greensock.TweenMax;
	import com.gskinner.geom.ColorMatrix;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	
	public class RolloverController {
		
		private var rollover:Dictionary;
		
		public var onSelected:Function;
		public var onNotSelected:Function;
		public var onNoSelection:Function;
		
		private var _enabled:Boolean = true;
		private var overClip:Sprite;
		
		private var _hitDoctor:HitDoctor;
		
		
		public function RolloverController() {
			_hitDoctor = new HitDoctor();
			_hitDoctor.addEventListener(HitDoctorEvent.NEW_PATIENT, mouseOver, false, 0, true);
			_hitDoctor.addEventListener(HitDoctorEvent.NO_PATIENT, mouseOut, false, 0, true);
			
			rollover = new Dictionary(true);
			OverwriteManager.init(OverwriteManager.ALL_IMMEDIATE);			
		}
		
		
		public function addRollover(clip:Sprite, shape:Boolean = true):void {
			
			//
			//  Prepare rollover effects and store them in our Dictionary
			//
			rollover[clip] = { };
			
			var clipFilters:Array = clip.filters;
			clipFilters.push(new BlurFilter(0, 0, 1));
			rollover[clip].blur = clipFilters.length - 1;
			
			clipFilters.push(new ColorMatrixFilter());
			rollover[clip].color = clipFilters.length - 1;
			rollover[clip].matrix = new ColorMatrix();
			rollover[clip].saturation = 0;
			
			rollover[clip].tint = new ColorTransform();
			
			rollover[clip].filters = clipFilters;
			//
			//  Listen for MOUSE_OVER
			//
			hitDoctor.addPatient(clip, shape);
			
			clip.mouseChildren = false;
		}
		
		
		public function isRollover(clip:Sprite):Boolean {
			return clip in rollover;
		}
		
		public function doRollover(clip:Sprite):void {
			overClip = clip;
			
			for (var key:Object in rollover) {
				var clip:Sprite = key as Sprite;
				if (clip == overClip) {
					removeFX(clip, true);
					if (onSelected != null) onSelected(clip, rollover[clip]);
				} else {
					rolloverFX(clip);
					if (onNotSelected != null) onNotSelected(clip, rollover[clip]);
				}
			}
		}
		
		private function mouseOver(e:HitDoctorEvent):void {
			if (e.ignored) return;
			if (!_enabled) return;
			//
			//  Apply rollover effects to all but the clip the mouse is over
			//
			doRollover(e.patient as Sprite);
		}
		
		private function mouseOut(e:HitDoctorEvent):void {
			if (e.ignored) return;
			if (!_enabled) return;
			//
			//  Confirm that the mouse is not still over the current rollover area
			//
			if (overClip != null) {
				if (overClip.hitTestPoint(overClip.parent.mouseX, overClip.parent.mouseY)) return;
			}
			rollOut();
		}
		
		public function rollOut():void {
			//
			//  The mouse is not over any rollover object...
			//
			for (var key:Object in rollover) {
				var clip:Sprite = key as Sprite;
				removeFX(clip);
				if (onNoSelection != null) onNoSelection(clip, rollover[clip]);
			}
			overClip = null;
			_hitDoctor.clear();
		}
		
		
		private function rolloverFX(clip:Sprite):void {
			//
			//  Apply rollover effects to a clip
			//
			TweenMax.to(rollover[clip].tint, 0.4, {
				redMultiplier:0.80, redOffset: -100, 
				blueMultiplier:0.20, blueOffset: -100, 
				greenMultiplier:0.20, greenOffset: -100
			} );
			TweenMax.to(rollover[clip].filters[rollover[clip].blur], 0.4, {
				blurX: 5, blurY: 5,
				onUpdate: updateFX, onUpdateParams: [clip], overwrite:3
			} );
			TweenMax.to(rollover[clip], 0.4, {
				saturation: 0,
				onUpdate: updateMatrix, onUpdateParams: [clip]
			} );
		}
		
		
		private function removeFX(clip:Sprite, quickly:Boolean = false):void {
			//
			//  Remove rollover effects from a clip
			//
			TweenMax.to(rollover[clip].tint, (quickly ? 0.3 : 0.7), {
				redMultiplier:1, redOffset: 0, 
				blueMultiplier:1, blueOffset: 0, 
				greenMultiplier:1, greenOffset: 0,
				ease: (quickly ? Quad.easeOut : Quad.easeIn)
			} );
			TweenMax.to(rollover[clip].filters[rollover[clip].blur],  (quickly ? 0.3 : 0.7), {
				blurX: 0, blurY: 0,
				ease: (quickly ? Quad.easeOut : Quad.easeIn),
				onUpdate: updateFX, onUpdateParams: [clip]
			} );
			TweenMax.to(rollover[clip], 0.5, {
				saturation: 0,
				ease: Quad.easeInOut,
				onUpdate: updateMatrix, onUpdateParams: [clip]
			} );
		}
		
		
		private function updateFX(clip:Sprite):void {
			if (clip != null && rollover != null) {
				if (rollover[clip] != null) {
					clip.transform.colorTransform = rollover[clip].tint;
					clip.filters = rollover[clip].filters;
				}
			}
		}
		
		//-------------------------------------------------------------
		
		private function disabledFX(clip:Sprite):void {
			TweenMax.to(rollover[clip].tint, 0.75, {
				redMultiplier:0.4, redOffset: 0, 
				blueMultiplier:0.4, blueOffset: 0, 
				greenMultiplier:0.4, greenOffset: 0,
				ease: Quad.easeOut, overwrite:1
			} );
			TweenMax.to(rollover[clip], 0.75, {
				saturation: -200,
				ease: Quad.easeInOut,
				onUpdate: updateMatrix, onUpdateParams: [clip]
			} );
		}
		
		private function updateMatrix(clip:Sprite):void {
			var colorFilter:ColorMatrixFilter = rollover[clip].filters[rollover[clip].color];
			var colorMatrix:ColorMatrix = rollover[clip].matrix;
			var saturation:Number = rollover[clip].saturation;
			
			colorMatrix.reset();
			colorMatrix.adjustSaturation(saturation);
			colorMatrix.adjustBrightness(saturation * 0.4);
			colorMatrix.adjustContrast(-saturation * 0.5);
			colorFilter.matrix = colorMatrix;
			
			updateFX(clip);
		}
		
		//-------------------------------------------------------------
		
		private function enableDisable():void {
			//
			//  Apply (or remove) disabled effects to all but the clip the mouse is over
			//
			for (var key:Object in rollover) {
				var clip:Sprite = key as Sprite;
				//clip.buttonMode = _enabled;
				if (_enabled) {
					if (overClip != null) {
						if (clip == overClip) {
							removeFX(clip);
						} else {
							rolloverFX(clip);
						}
					}
				} else {
					if (clip == overClip) {
						removeFX(clip);
					} else {
						disabledFX(clip);
					}
				}
			}
		}
		
		public function get enabled():Boolean { return _enabled; }
		
		public function set enabled(value:Boolean):void {
			_enabled = value;
			_hitDoctor.enabled = value;
			enableDisable();
		}
		
		
		public function get hitDoctor():HitDoctor { return _hitDoctor; }
		
		//-------------------------------------------------------------
		
		public function dispose():void {
			for (var key:Object in rollover) {
				var clip:MovieClip = key as MovieClip;
				if (clip != null) {
					clip.removeEventListener(MouseEvent.MOUSE_OVER, mouseOver);
					clip.removeEventListener(MouseEvent.MOUSE_OUT, mouseOut);
					clip.removeEventListener(Event.DEACTIVATE, mouseOut);
					TweenMax.killTweensOf(clip);
				}
				TweenMax.killTweensOf(rollover[key]);
				delete rollover[key];
			}
			rollover = null;
			
			_hitDoctor.dispose();
			_hitDoctor = null;
			
		}
		
	}
}