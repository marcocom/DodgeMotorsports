package com.dodgems.grid {
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class HitDoctor extends EventDispatcher {
		
		[Event(name='HitDoctorEvent.NEW_PATIENT', type="com.dodgems.common.HitDoctorEvent")]
		[Event(name='HitDoctorEvent.NO_PATIENT', type="com.dodgems.common.HitDoctorEvent")]
		
		private var _currentPatient:DisplayObject;
		private var patients:Dictionary;
		
		/// "active" becomes true when HitDoctor succesfully adds an en event listener to the stage
		private var active:Boolean = false;
		
		private var stage:Stage;
		private var onEnterFrame:Boolean;
		
		public var enabled:Boolean = true;
		
		
		public function HitDoctor(onEnterFrame:Boolean = false) {
			this.onEnterFrame = onEnterFrame;
			patients = new Dictionary(true);
		}
		
		
		public function addPatient(patient:DisplayObject, shape:Boolean = true):void {
			patients[patient] = shape;
			
			if (!active) {
				if (patient.stage) {
					activate(patient.stage);
				} else {
					patient.addEventListener(Event.ADDED_TO_STAGE, patientOnStage, false, 0, true);
				}
			}
		}
		
		private function patientOnStage(e:Event):void {
			var patient:DisplayObject = e.target as DisplayObject;
			patient.removeEventListener(Event.ADDED_TO_STAGE, patientOnStage);
			if (!active) activate(patient.stage);
		}
		
		
		private function activate(stage:Stage):void {
			this.stage = stage;
			if (onEnterFrame) {
				stage.addEventListener(Event.ENTER_FRAME, hitTest, false, 0, true);
			} else {
				stage.addEventListener(MouseEvent.MOUSE_MOVE, hitTest, false, 0, true);
			}
			active = true;
		}
		
		public function clear():void {
			_currentPatient = null;
		}
		
		private function hitTest(e:Event):void {
			if (!enabled) return;
			
			//
			// Test the current patient
			//
			if (_currentPatient) {
				//
				//  If we're still over the current patient, then there's no change
				//
				if (overPatient(_currentPatient)) return;
			}
			
			//
			// Test for a new patient
			//
			var oldPatient:DisplayObject = _currentPatient;
			var event:HitDoctorEvent
			var patient:DisplayObject;
			for (var key:Object in patients) {
				patient = key as DisplayObject;
				if (overPatient(patient)) {
					_currentPatient = patient;
					event = new HitDoctorEvent(HitDoctorEvent.NEW_PATIENT, patient);
					dispatchEvent(event);
					if (event.ignored) _currentPatient = oldPatient;
					return;
				}
			}
			
			//
			// Have we lost a patient?
			//
			if (_currentPatient) {
				_currentPatient = null;
				event = new HitDoctorEvent(HitDoctorEvent.NO_PATIENT);
				dispatchEvent(event);
				if (event.ignored) _currentPatient = oldPatient;
			}
		}
		
		
		private function overPatient(patient:DisplayObject):Boolean {
			//
			//  Is the mouse over the patient?
			//
			var stage:Stage = patient.stage;
			if (stage) {
				var mouseX:Number = stage.mouseX;
				var mouseY:Number = stage.mouseY;
				return patient.hitTestPoint(mouseX, mouseY, patients[patient]);
			}
			return false;
		}
		
		
		public function removePatient(patient:DisplayObject):void {
			delete patients[patient];
		}
		
		
		public function dispose():void {
			for (var patient:Object in patients) {
				patient.removeEventListener(Event.ADDED_TO_STAGE, patientOnStage);
				delete patients[patient];
			}
			patients = null;
			
			if (onEnterFrame) {
				stage.removeEventListener(Event.ENTER_FRAME, hitTest);
			} else {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, hitTest);
			}
			stage = null;
		}
		
		
		//---------------------------------
		// Read-Only Properties
		//---------------------------------
		
		public function get currentPatient():DisplayObject { return _currentPatient; }
		
	}
}