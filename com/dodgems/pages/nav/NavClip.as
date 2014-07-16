﻿package com.dodgems.pages.nav{	import com.gaiaframework.templates.AbstractPage;	import com.gaiaframework.events.*;	import com.gaiaframework.debug.*;	import com.gaiaframework.api.*;	import flash.media.Sound;	import flash.media.SoundChannel;	import flash.media.SoundTransform;		import flash.display.*;	import flash.events.*;	import flash.net.URLLoader;	import flash.net.URLRequest;	import flash.net.navigateToURL;	import flash.geom.Rectangle;	import com.greensock.TweenMax;	import com.greensock.easing.*	import com.dodgems.pages.nav.NavElement;	import com.dodgems.Global;		public class NavClip extends Sprite {				private var navArr:Array;		private var navSpacer:Number = 43;				private var bgWidth:Number = 200;		private var bgHeight:Number = 490;				public var logo:MovieClip;		public var logoStartX:Number;		public var logoStartY:Number;				private var navFunc:Function;				private var dataXML:XMLList;				private var navContainer:Sprite;		private var navTop:Sprite;		private var navBot:Sprite;				private var isVert:Boolean = true;				public var bgClip:Sprite;		public var totalSections:Number;		private var sndChannel:SoundChannel;		private var sndRollOver:airGun1;		private var currentLink:NavElement;						public function NavClip(dat:XMLList, navCallback:Function) {			dataXML = dat;			navFunc = navCallback;						init();			alpha = 0.3;		}						public function init():void {			logoStartX = logo.x;			logoStartY = logo.y;			logo.addEventListener(MouseEvent.CLICK, logoClick, false, 0, true);			logo.buttonMode = true;						navTop = new Sprite();			navBot = new Sprite();						bgClip = new Sprite();			bgClip.graphics.beginFill(0x000000, 30);			bgClip.graphics.drawRect(0, 0, bgWidth, bgHeight);			bgClip.graphics.endFill();			addChild(bgClip);			addChild(logo);						buildNav();		}						public function buildNav():void {						navArr = new Array();			navContainer = new Sprite();			addChild(navContainer);						for (var i:Number = 0; i < dataXML.elements().length(); i++){								var id:String = dataXML.nav[i].@id;				var navname:String = dataXML.nav[i].@title;				var rot:Number = dataXML.nav[i].@rotation;				var en:Boolean = (dataXML.nav[i].@enabled == "true");				var isHidden:Boolean = (dataXML.nav[i].@hide == "true");								if (!isHidden) {										var mc:NavElement = new NavElement( navname, id, en,  i);					mc.name = "nav"+i;					navContainer.addChild(mc);										mc.y = (logo.y + logo.height) + ((i+1)*navSpacer);										mc.x = (bgWidth/2);					mc.rotation = rot;										navArr.push(mc);										if (en) mc.hit.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);					if (en) mc.hit.addEventListener(MouseEvent.MOUSE_DOWN, onDown, false, 0, true);					mc.hit.addEventListener(MouseEvent.MOUSE_OVER, onOver, false, 0, true);					mc.hit.addEventListener(MouseEvent.MOUSE_OUT, onOut, false, 0, true);					mc.hit.buttonMode = true;				}			}		}						public function rePosition(vert:Boolean):void {			var cur:String = Gaia.api.getCurrentBranch();						if (cur == "index/nav/home") {				logo.x = logoStartX;				logo.y = logoStartY;				bgClip.visible = true;			} else {				if(!vert){					logo.x = -180;					logo.y = 10;				} else {					logo.y = -100;					logo.x = logoStartX;				}				bgClip.visible = false;			}			if (!vert) {				navContainer.addChild(navTop);				navContainer.addChild(navBot);				navContainer.x = -250;								navTop.y = 20;				navTop.x = 70;				navBot.y = 55;			} else {				navContainer.x = 0;			}						var rowcount:Number = 0;			for (var i:Number = 0; i < navArr.length; i++) {								var linkname:String = "nav"+i;				var link:NavElement = navArr[i];				navContainer.addChild(link);								if (!vert) {					//					//  HORIZONTAL					//					if (i < 4) {						navTop.addChild(link);						link.x = 205 + (navArr[0].field.textWidth * 0.5) + (125 * i); //  navTop.width + 75;						if (i == 2) link.x -= 36;	// ugh...						if (i == 1) link.x -= 15;	// I think I'm going to be sick.					} else {						navBot.addChild(link);						//link.x = navBot.width + 75;						link.x = 205 + (navArr[4].field.textWidth * 0.5) + (155 * (i - 4));						if (i == 5) link.x -= 30;	// Dandy coding, eh?						if (i == 6) link.x -= 20;	// How clever!					}										link.y = 0;					link.rotation = 0;				} else {					//					//  VERTICAL					//					navContainer.addChild(link);					if (cur == "index/nav/home") {						link.y = (logo.y + logo.height) + ((i + 1) * navSpacer);					} else {						link.y = 44 + ((i + 1) * navSpacer);					}					link.x = (bgWidth/2);					link.rotation = dataXML.nav[i].@rotation;				}			}						navBot.x = navTop.x;		}								private function logoClick(e:MouseEvent):void {			var section:String = Gaia.api.getCurrentBranch().split("/")[2];			if (section != "home") navFunc("home", true);		}						private function linkOut(url:String):void {trace("NavClip.linkOut(DISABLED) " + url);			navigateToURL(new URLRequest(url), "_blank");		}				private function onDown(e:MouseEvent):void {			//playAirGunSFX();		}				private function onClick(e:MouseEvent):void {trace("NavClip.onClick()");			var link:NavElement = e.currentTarget.parent as NavElement;			var i:int = link.index;						if (currentLink != null) currentLink.lockRollover(false);			currentLink = link;			currentLink.lockRollover(true);						if (dataXML.nav[i].@enabled == "true"){				if (dataXML.nav[i].@url == "site"){					var section:String = Gaia.api.getCurrentBranch().split("/")[2];					if (dataXML.nav[i].@id != section) navFunc(dataXML.nav[i].@id, true);				} else {					linkOut(dataXML.nav[i].@url);				}			}		}				public function selectID(id:String = "*none*"):void {trace("NavClip.selectiID('" + id + "');");						currentLink = null;			for (var i:int = 0; i < navArr.length; i++) {				var link:NavElement = navArr[i];				if (link.linkID == id) {					link.lockRollover(true);					currentLink = link;									} else {					link.lockRollover(false);				}			}					}				private function playAirGunSFX():void {			sndRollOver = new airGun1();			sndChannel = sndRollOver.play();			var st:SoundTransform = new SoundTransform();			st.volume = Global.GLOBALVOLUME;			sndChannel.soundTransform = st;		}						private function onOver(e:MouseEvent):void {			//playAirGunSFX();						var navLink:NavElement = e.currentTarget.parent as NavElement;						if (!isVert){				navLink.parent.addChildAt(navLink, 0);				navLink.parent.parent.addChildAt(navLink.parent, 0);			}						navLink.revealRollover(true);		}						private function onOut(e:MouseEvent):void {			var navLink:NavElement = e.currentTarget.parent as NavElement;			navLink.revealRollover(false);		}					}}