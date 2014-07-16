﻿package com.dodgems.pages.home{    import flash.display.Sprite;    import flash.events.*;    import flash.media.Video;	import flash.media.SoundTransform;	import flash.media.SoundMixer;    import flash.net.NetConnection;    import flash.net.NetStream;	import com.dodgems.Global;	public class VideoPlayback extends Sprite {		        private var url:String;		private var movWidth:Number;		private var movHeight:Number;		private var movDuration:Number;		private var movInst:String;		private var stream:NetStream;		private var connection:NetConnection;		private var video:Video;		private var sound:SoundTransform;		private var muteStatus:Boolean = false;		private var _lastVolume:Number = 1;		private var nextFunc:Function;		private var startFunc:Function;		private var _buffering:Boolean = true;		        public function VideoPlayback($asset:String, $w:Number, $h:Number, $nextFunc:Function, $startFunc:Function) {			url = $asset;			movWidth = $w;			movHeight = $h;			nextFunc = $nextFunc;			startFunc = $startFunc;			_lastVolume = Global.GLOBALVOLUME;			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);		}				public function onAddedToStage(event:Event):void {						removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);						connection = new NetConnection();			connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);			connection.connect(null);						connectStream();		}		        private function connectStream():void {			if (stream == null) {				stream = new NetStream(connection);				stream.bufferTime = 12;				stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);				stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler, false, 0, true);								var client:Object = new Object();				client.onMetaData = onMetaData;				stream.client = client;			}						if (video == null) {				video = new Video();				video.attachNetStream(stream);				video.smoothing = true;				video.width = movWidth;				video.height = movHeight;				stream.play(url);					stream.seek(0);				stream.pause();				addChild(video);			}						sound = new SoundTransform();			if (muteStatus) mute(true) else setvolume(_lastVolume);			startFunc();        }				private function onMetaData(data:Object):void {		   movDuration = data.duration;      		}				private function asyncErrorHandler(event:AsyncErrorEvent):void {			// ignore AsyncErrorEvent events.		}		        private function netStatusHandler(event:NetStatusEvent):void {            switch (event.info.code) {				                case "NetConnection.Connect.Success":                    connectStream();                    break;					                case "NetStream.Play.StreamNotFound":                    trace("WARNING", "Unable to locate video: " + url);                    break;									case "NetStream.Play.Stop":					//playVid();					trace("PLAYING NEXT MOVIE");					nextFunc(true);					break;									case "NetStream.Play.Start":				case "NetStream.Buffer.Empty":trace("<V> " + event.info.code);					_buffering = true;					break;									case "NetStream.Buffer.Full":				case "NetStream.Buffer.Flush":trace("<V> " + event.info.code);					_buffering = false;					break;								default:trace("<V> Unhandled: " + event.info.code + "  _buffering: " + _buffering);					break;				            }        }				public function get buffering():Boolean { return _buffering; }						public function mute(muted:Boolean):void {            muteStatus = muted;			var s:SoundTransform = new SoundTransform((muted ? 0 : _lastVolume),0);            			stream.soundTransform = s;			this.soundTransform = s;        }		        public function setvolume(vol:Number):void {   			var vs:SoundTransform = new SoundTransform(vol, 0);			_lastVolume = vol;			stream.soundTransform = vs;			this.soundTransform = vs;        }						public function unloadVid():void {						SoundMixer.stopAll(); 						if (stream != null) stream.close();			if (url != null) video.clear();			if (connection != null) connection.close();			if (video != null) removeChild(video);			url = null;			connection = null;			stream = null;			video = null;			startFunc = null;		}				public function changeVideo(asset:String):void {						unloadVid();			url = asset;			onAddedToStage(null);		}				public function playVid():void {			stream.seek(0);			stream.resume();		}				public function pauseVid():void {			stream.pause();		}				public function resumeVid():void {			stream.resume();		}				public function get vidInstance():String {			return movInst;		}				public function set vidInstance(value:String):void {			movInst = value;		}				public function get vidDuration():Number {			return movDuration;		}				public function get vidTime():Number {			return stream.time;		}				public function get vidLoaded():Number {			var currPercent:Number = Math.round(stream.bytesLoaded / stream.bytesTotal);			return currPercent;		}				public function get vidPlayed():Number {			var currPercent:Number = ( stream.time / movDuration);			return currPercent;		}				public function vidSeek(num:Number):void {			stream.seek(num);		}				public function set _vidWidth(num:Number):void {			video.width = num;		}				public function set _vidHeight(num:Number):void {			video.height = num;		}				public function get _volume():Number {			return _lastVolume;		}		    }}