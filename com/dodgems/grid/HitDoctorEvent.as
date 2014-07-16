package com.dodgems.grid {
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author David Barlia - david@barliesque.com
	 */
	public class HitDoctorEvent extends Event {
		
		static public const NEW_PATIENT:String = "HitDoctorEvent.NEW_PATIENT";
		static public const NO_PATIENT:String = "HitDoctorEvent.NO_PATIENT";
		
		public var patient:DisplayObject;
		public var ignored:Boolean;
		
		public function HitDoctorEvent(type:String, patient:DisplayObject = null) {
			super(type);
			this.patient = patient;
			ignored = false;
		}
		
	}
}