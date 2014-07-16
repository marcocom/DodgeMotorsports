﻿/****************************************************************************************************** Gaia Framework for Adobe Flash ©2007-2009* Author: Steven Sacks** blog: http://www.stevensacks.net/* forum: http://www.gaiaflashframework.com/forum/* wiki: http://www.gaiaflashframework.com/wiki/* * By using the Gaia Framework, you agree to keep the above contact information in the source code.* * Gaia Framework for Adobe Flash is released under the GPL License:* http://www.opensource.org/licenses/gpl-2.0.php *****************************************************************************************************/package com.dodgems.pages{	import com.dodgems.Global;	import com.gaiaframework.templates.AbstractPreloader;	import com.gaiaframework.api.Gaia;	import com.gaiaframework.events.*;	import com.greensock.TweenMax;	import com.greensock.easing.*;	import flash.display.*;	import flash.events.*;	import flash.text.*;	public class PreloaderScaffold extends Sprite	{		private static const LOADERWIDTH:Number = 600;		private static const LOADERHEIGHT:Number = 150;		private static const ANIMTRAVEL:Number = 20;		public var TXT_Overall:TextField;		public var TXT_Asset:TextField;		public var TXT_Bytes:TextField;				public var percTxt:TextField;		public var loaderTxt:TextField;				public var MC_Bar:MovieClip;		public var animClip:MovieClip;		public var loaderMask:MovieClip;				public var isOpened:Boolean;						private var loaderTxtSpacer:Number;		private var percLoaded:Number;				private var startX:Number;		private var animY:Number;				public function PreloaderScaffold() {			super();			visible = false;			mouseEnabled = mouseChildren = false;			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);		}						private function onAddedToStage(event:Event):void {			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);						stage.addEventListener(Event.RESIZE, onResize, false, 0, true);			isOpened = false;			onResize();			loaderTxtSpacer = percTxt.x - MC_Bar.x + MC_Bar.width;		}						public function transitionIn():void {			if (!startX) startX = x;			x = startX;			//alpha = 0;			//TweenMax.from(this, 1.0, {alpha: 1, x:stage.stageWidth, ease:Strong.easeInOut});			TweenMax.from(this, 1.0, { x:stage.stageWidth, ease:Strong.easeInOut } );			isOpened = true;			addEventListener(Event.ENTER_FRAME, onFrame, false, 0, true);		}						public function transitionOut():void {			removeEventListener(Event.ENTER_FRAME, onFrame);			//alpha = 1;			//TweenMax.to(this, 0.6, { alpha: 0, x: -Global.NATIVEWIDTH, ease:Strong.easeInOut, onComplete:setVisible } );			TweenMax.to(this, 0.6, { x: -Global.NATIVEWIDTH, ease:Strong.easeInOut, onComplete:setVisible } );		}						public function setVisible():void {			this.visible = false;		}						public function onProgress(event:AssetEvent):void {			// if bytes, don't show if loaded = 0, if not bytes, don't show if perc = 0			// the reason is because all the files might already be loaded so no need to show preloader			visible = event.bytes ? (event.loaded > 0 && isOpened) : (event.perc > 0 && isOpened);						percLoaded = event.perc;						var flip:Number = Math.abs(percLoaded - 1);			animY = loaderMask.y + (loaderMask.height * flip);		}						private function onFrame(e:Event):void {			if (percLoaded > 0){								MC_Bar.scaleX -= (MC_Bar.scaleX - percLoaded)*.2;				var percX:Number = MC_Bar.x + MC_Bar.width + loaderTxtSpacer;				percTxt.text = Math.round(percLoaded * 100) + "%";				percTxt.x = percX;								animClip.y = animY;				//x -= (percLoaded * ANIMTRAVEL);			}					}						private function onResize(event:Event = null):void {			x = (Gaia.api.getWidth() - LOADERWIDTH) / 2;			y = 300;		}					}}