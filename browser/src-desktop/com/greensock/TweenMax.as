package com.greensock
{
   import com.greensock.core.PropTween;
   import com.greensock.core.SimpleTimeline;
   import com.greensock.core.TweenCore;
   import com.greensock.events.TweenEvent;
   import com.greensock.plugins.AutoAlphaPlugin;
   import com.greensock.plugins.BevelFilterPlugin;
   import com.greensock.plugins.BezierPlugin;
   import com.greensock.plugins.BezierThroughPlugin;
   import com.greensock.plugins.BlurFilterPlugin;
   import com.greensock.plugins.ColorMatrixFilterPlugin;
   import com.greensock.plugins.ColorTransformPlugin;
   import com.greensock.plugins.DropShadowFilterPlugin;
   import com.greensock.plugins.EndArrayPlugin;
   import com.greensock.plugins.FrameLabelPlugin;
   import com.greensock.plugins.FramePlugin;
   import com.greensock.plugins.GlowFilterPlugin;
   import com.greensock.plugins.HexColorsPlugin;
   import com.greensock.plugins.RemoveTintPlugin;
   import com.greensock.plugins.RoundPropsPlugin;
   import com.greensock.plugins.ShortRotationPlugin;
   import com.greensock.plugins.TintPlugin;
   import com.greensock.plugins.TweenPlugin;
   import com.greensock.plugins.VisiblePlugin;
   import com.greensock.plugins.VolumePlugin;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import flash.utils.Dictionary;
   import flash.utils.getTimer;
   
   public class TweenMax extends TweenLite implements IEventDispatcher
   {
      
      private static var _overwriteMode:int = !!OverwriteManager.enabled?int(OverwriteManager.mode):int(OverwriteManager.init(2));
      
      public static const version:Number = 11.698;
      
      public static var killTweensOf:Function = TweenLite.killTweensOf;
      
      public static var killDelayedCallsTo:Function = TweenLite.killTweensOf;
      
      {
         TweenPlugin.activate([AutoAlphaPlugin,EndArrayPlugin,FramePlugin,RemoveTintPlugin,TintPlugin,VisiblePlugin,VolumePlugin,BevelFilterPlugin,BezierPlugin,BezierThroughPlugin,BlurFilterPlugin,ColorMatrixFilterPlugin,ColorTransformPlugin,DropShadowFilterPlugin,FrameLabelPlugin,GlowFilterPlugin,HexColorsPlugin,RoundPropsPlugin,ShortRotationPlugin,{}]);
      }
      
      protected var _cyclesComplete:int = 0;
      
      protected var _dispatcher:EventDispatcher;
      
      protected var _hasUpdateListener:Boolean;
      
      protected var _easeType:int;
      
      protected var _repeatDelay:Number = 0;
      
      public var yoyo:Boolean;
      
      protected var _easePower:int;
      
      protected var _repeat:int = 0;
      
      public function TweenMax(param1:Object, param2:Number, param3:Object)
      {
         super(param1,param2,param3);
         if(TweenLite.version < 11.2)
         {
            throw new Error("TweenMax error! Please update your TweenLite class or try deleting your ASO files. TweenMax requires a more recent version. Download updates at http://www.TweenMax.com.");
         }
         this.yoyo = Boolean(this.vars.yoyo);
         _repeat = uint(this.vars.repeat);
         _repeatDelay = !!this.vars.repeatDelay?Number(Number(this.vars.repeatDelay)):Number(0);
         this.cacheIsDirty = true;
         if(this.vars.onCompleteListener || this.vars.onInitListener || this.vars.onUpdateListener || this.vars.onStartListener || this.vars.onRepeatListener || this.vars.onReverseCompleteListener)
         {
            initDispatcher();
            if(param2 == 0 && _delay == 0)
            {
               _dispatcher.dispatchEvent(new TweenEvent(TweenEvent.UPDATE));
               _dispatcher.dispatchEvent(new TweenEvent(TweenEvent.COMPLETE));
            }
         }
         if(this.vars.timeScale && !(this.target is TweenCore))
         {
            this.cachedTimeScale = this.vars.timeScale;
         }
      }
      
      public static function set globalTimeScale(param1:Number) : void
      {
         if(param1 == 0)
         {
            param1 = 0.0001;
         }
         if(TweenLite.rootTimeline == null)
         {
            TweenLite.to({},0,{});
         }
         var _loc2_:SimpleTimeline = TweenLite.rootTimeline;
         var _loc3_:Number = getTimer() * 0.001;
         _loc2_.cachedStartTime = _loc3_ - (_loc3_ - _loc2_.cachedStartTime) * _loc2_.cachedTimeScale / param1;
         _loc2_ = TweenLite.rootFramesTimeline;
         _loc3_ = TweenLite.rootFrame;
         _loc2_.cachedStartTime = _loc3_ - (_loc3_ - _loc2_.cachedStartTime) * _loc2_.cachedTimeScale / param1;
         TweenLite.rootFramesTimeline.cachedTimeScale = TweenLite.rootTimeline.cachedTimeScale = param1;
      }
      
      public static function fromTo(param1:Object, param2:Number, param3:Object, param4:Object) : TweenMax
      {
         if(param4.isGSVars)
         {
            param4 = param4.vars;
         }
         if(param3.isGSVars)
         {
            param3 = param3.vars;
         }
         param4.startAt = param3;
         if(param3.immediateRender)
         {
            param4.immediateRender = true;
         }
         return new TweenMax(param1,param2,param4);
      }
      
      public static function allFromTo(param1:Array, param2:Number, param3:Object, param4:Object, param5:Number = 0, param6:Function = null, param7:Array = null) : Array
      {
         if(param4.isGSVars)
         {
            param4 = param4.vars;
         }
         if(param3.isGSVars)
         {
            param3 = param3.vars;
         }
         param4.startAt = param3;
         if(param3.immediateRender)
         {
            param4.immediateRender = true;
         }
         return allTo(param1,param2,param4,param5,param6,param7);
      }
      
      public static function pauseAll(param1:Boolean = true, param2:Boolean = true) : void
      {
         changePause(true,param1,param2);
      }
      
      public static function getTweensOf(param1:Object) : Array
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc2_:Array = masterList[param1];
         var _loc3_:Array = [];
         if(_loc2_)
         {
            _loc4_ = _loc2_.length;
            _loc5_ = 0;
            while(--_loc4_ > -1)
            {
               if(!TweenLite(_loc2_[_loc4_]).gc)
               {
                  _loc3_[_loc5_++] = _loc2_[_loc4_];
               }
            }
         }
         return _loc3_;
      }
      
      public static function get globalTimeScale() : Number
      {
         return TweenLite.rootTimeline == null?Number(1):Number(TweenLite.rootTimeline.cachedTimeScale);
      }
      
      public static function killChildTweensOf(param1:DisplayObjectContainer, param2:Boolean = false) : void
      {
         var _loc4_:Object = null;
         var _loc5_:DisplayObjectContainer = null;
         var _loc3_:Array = getAllTweens();
         var _loc6_:int = _loc3_.length;
         while(--_loc6_ > -1)
         {
            _loc4_ = _loc3_[_loc6_].target;
            if(_loc4_ is DisplayObject)
            {
               _loc5_ = _loc4_.parent;
               while(_loc5_)
               {
                  if(_loc5_ == param1)
                  {
                     if(param2)
                     {
                        _loc3_[_loc6_].complete(false);
                     }
                     else
                     {
                        _loc3_[_loc6_].setEnabled(false,false);
                     }
                  }
                  _loc5_ = _loc5_.parent;
               }
               continue;
            }
         }
      }
      
      public static function delayedCall(param1:Number, param2:Function, param3:Array = null, param4:Boolean = false) : TweenMax
      {
         return new TweenMax(param2,0,{
            "delay":param1,
            "onComplete":param2,
            "onCompleteParams":param3,
            "immediateRender":false,
            "useFrames":param4,
            "overwrite":0
         });
      }
      
      public static function isTweening(param1:Object) : Boolean
      {
         var _loc4_:TweenLite = null;
         var _loc2_:Array = getTweensOf(param1);
         var _loc3_:int = _loc2_.length;
         while(--_loc3_ > -1)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_.active || _loc4_.cachedStartTime == _loc4_.timeline.cachedTime && _loc4_.timeline.active)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function killAll(param1:Boolean = false, param2:Boolean = true, param3:Boolean = true) : void
      {
         var _loc5_:* = false;
         var _loc4_:Array = getAllTweens();
         var _loc6_:int = _loc4_.length;
         while(--_loc6_ > -1)
         {
            _loc5_ = _loc4_[_loc6_].target == _loc4_[_loc6_].vars.onComplete;
            if(_loc5_ == param3 || _loc5_ != param2)
            {
               if(param1)
               {
                  _loc4_[_loc6_].complete(false);
               }
               else
               {
                  _loc4_[_loc6_].setEnabled(false,false);
               }
            }
         }
      }
      
      private static function changePause(param1:Boolean, param2:Boolean = true, param3:Boolean = false) : void
      {
         var _loc5_:* = false;
         var _loc4_:Array = getAllTweens();
         var _loc6_:int = _loc4_.length;
         while(--_loc6_ > -1)
         {
            _loc5_ = TweenLite(_loc4_[_loc6_]).target == TweenLite(_loc4_[_loc6_]).vars.onComplete;
            if(_loc5_ == param3 || _loc5_ != param2)
            {
               TweenCore(_loc4_[_loc6_]).paused = param1;
            }
         }
      }
      
      public static function from(param1:Object, param2:Number, param3:Object) : TweenMax
      {
         if(param3.isGSVars)
         {
            param3 = param3.vars;
         }
         param3.runBackwards = true;
         if(!("immediateRender" in param3))
         {
            param3.immediateRender = true;
         }
         return new TweenMax(param1,param2,param3);
      }
      
      public static function allFrom(param1:Array, param2:Number, param3:Object, param4:Number = 0, param5:Function = null, param6:Array = null) : Array
      {
         if(param3.isGSVars)
         {
            param3 = param3.vars;
         }
         param3.runBackwards = true;
         if(!("immediateRender" in param3))
         {
            param3.immediateRender = true;
         }
         return allTo(param1,param2,param3,param4,param5,param6);
      }
      
      public static function getAllTweens() : Array
      {
         var _loc4_:Array = null;
         var _loc5_:int = 0;
         var _loc1_:Dictionary = masterList;
         var _loc2_:int = 0;
         var _loc3_:Array = [];
         for each(_loc4_ in _loc1_)
         {
            _loc5_ = _loc4_.length;
            while(--_loc5_ > -1)
            {
               if(!TweenLite(_loc4_[_loc5_]).gc)
               {
                  _loc3_[_loc2_++] = _loc4_[_loc5_];
               }
            }
         }
         return _loc3_;
      }
      
      public static function resumeAll(param1:Boolean = true, param2:Boolean = true) : void
      {
         changePause(false,param1,param2);
      }
      
      public static function to(param1:Object, param2:Number, param3:Object) : TweenMax
      {
         return new TweenMax(param1,param2,param3);
      }
      
      public static function allTo(param1:Array, param2:Number, param3:Object, param4:Number = 0, param5:Function = null, param6:Array = null) : Array
      {
         var i:int = 0;
         var varsDup:Object = null;
         var p:String = null;
         var onCompleteProxy:Function = null;
         var onCompleteParamsProxy:Array = null;
         var targets:Array = param1;
         var duration:Number = param2;
         var vars:Object = param3;
         var stagger:Number = param4;
         var onCompleteAll:Function = param5;
         var onCompleteAllParams:Array = param6;
         var l:int = targets.length;
         var a:Array = [];
         if(vars.isGSVars)
         {
            vars = vars.vars;
         }
         var curDelay:Number = "delay" in vars?Number(Number(vars.delay)):Number(0);
         onCompleteProxy = vars.onComplete;
         onCompleteParamsProxy = vars.onCompleteParams;
         var lastIndex:int = l - 1;
         i = 0;
         while(i < l)
         {
            varsDup = {};
            for(p in vars)
            {
               varsDup[p] = vars[p];
            }
            varsDup.delay = curDelay;
            if(i == lastIndex && onCompleteAll != null)
            {
               varsDup.onComplete = function():void
               {
                  if(onCompleteProxy != null)
                  {
                     onCompleteProxy.apply(null,onCompleteParamsProxy);
                  }
                  onCompleteAll.apply(null,onCompleteAllParams);
               };
            }
            a[i] = new TweenMax(targets[i],duration,varsDup);
            curDelay = curDelay + stagger;
            i = i + 1;
         }
         return a;
      }
      
      public function dispatchEvent(param1:Event) : Boolean
      {
         return _dispatcher == null?false:Boolean(_dispatcher.dispatchEvent(param1));
      }
      
      public function set timeScale(param1:Number) : void
      {
         if(param1 == 0)
         {
            param1 = 0.0001;
         }
         var _loc2_:Number = this.cachedPauseTime || this.cachedPauseTime == 0?Number(this.cachedPauseTime):Number(this.timeline.cachedTotalTime);
         this.cachedStartTime = _loc2_ - (_loc2_ - this.cachedStartTime) * this.cachedTimeScale / param1;
         this.cachedTimeScale = param1;
         setDirtyCache(false);
      }
      
      override public function renderTime(param1:Number, param2:Boolean = false, param3:Boolean = false) : void
      {
         var _loc7_:* = false;
         var _loc8_:Boolean = false;
         var _loc9_:Boolean = false;
         var _loc11_:Number = NaN;
         var _loc12_:int = 0;
         var _loc13_:int = 0;
         var _loc14_:Number = NaN;
         var _loc4_:Number = !!this.cacheIsDirty?Number(this.totalDuration):Number(this.cachedTotalDuration);
         var _loc5_:Number = this.cachedTime;
         var _loc6_:Number = this.cachedTotalTime;
         if(param1 >= _loc4_)
         {
            this.cachedTotalTime = _loc4_;
            this.cachedTime = this.cachedDuration;
            this.ratio = 1;
            _loc7_ = !this.cachedReversed;
            if(this.cachedDuration == 0)
            {
               if((param1 == 0 || _rawPrevTime < 0) && _rawPrevTime != param1)
               {
                  param3 = true;
               }
               _rawPrevTime = param1;
            }
         }
         else if(param1 <= 0)
         {
            if(param1 < 0)
            {
               this.active = false;
               if(this.cachedDuration == 0)
               {
                  if(_rawPrevTime >= 0)
                  {
                     param3 = true;
                     _loc7_ = _rawPrevTime > 0;
                  }
                  _rawPrevTime = param1;
               }
            }
            else if(param1 == 0 && !this.initted)
            {
               param3 = true;
            }
            this.cachedTotalTime = this.cachedTime = this.ratio = 0;
            if(this.cachedReversed && _loc6_ != 0)
            {
               _loc7_ = true;
            }
         }
         else
         {
            this.cachedTotalTime = this.cachedTime = param1;
            _loc9_ = true;
         }
         if(_repeat != 0)
         {
            _loc11_ = this.cachedDuration + _repeatDelay;
            _loc12_ = _cyclesComplete;
            if((_cyclesComplete = this.cachedTotalTime / _loc11_ >> 0) == this.cachedTotalTime / _loc11_ && _cyclesComplete != 0)
            {
               _cyclesComplete--;
            }
            _loc8_ = Boolean(_loc12_ != _cyclesComplete);
            if(_loc7_)
            {
               if(this.yoyo && _repeat % 2)
               {
                  this.cachedTime = this.ratio = 0;
               }
            }
            else if(param1 > 0)
            {
               this.cachedTime = this.cachedTotalTime - _cyclesComplete * _loc11_;
               if(this.yoyo && _cyclesComplete % 2)
               {
                  this.cachedTime = this.cachedDuration - this.cachedTime;
               }
               else if(this.cachedTime >= this.cachedDuration)
               {
                  this.cachedTime = this.cachedDuration;
                  this.ratio = 1;
                  _loc9_ = false;
               }
               if(this.cachedTime <= 0)
               {
                  this.cachedTime = this.ratio = 0;
                  _loc9_ = false;
               }
            }
            else
            {
               _cyclesComplete = 0;
            }
         }
         if(_loc5_ == this.cachedTime && !param3)
         {
            return;
         }
         if(!this.initted)
         {
            init();
         }
         if(!this.active && !this.cachedPaused)
         {
            this.active = true;
         }
         if(_loc9_)
         {
            if(_easeType)
            {
               _loc13_ = _easePower;
               _loc14_ = this.cachedTime / this.cachedDuration;
               if(_easeType == 2)
               {
                  this.ratio = _loc14_ = 1 - _loc14_;
                  while(--_loc13_ > -1)
                  {
                     this.ratio = _loc14_ * this.ratio;
                  }
                  this.ratio = 1 - this.ratio;
               }
               else if(_easeType == 1)
               {
                  this.ratio = _loc14_;
                  while(--_loc13_ > -1)
                  {
                     this.ratio = _loc14_ * this.ratio;
                  }
               }
               else if(_loc14_ < 0.5)
               {
                  this.ratio = _loc14_ = _loc14_ * 2;
                  while(--_loc13_ > -1)
                  {
                     this.ratio = _loc14_ * this.ratio;
                  }
                  this.ratio = this.ratio * 0.5;
               }
               else
               {
                  this.ratio = _loc14_ = (1 - _loc14_) * 2;
                  while(--_loc13_ > -1)
                  {
                     this.ratio = _loc14_ * this.ratio;
                  }
                  this.ratio = 1 - 0.5 * this.ratio;
               }
            }
            else
            {
               this.ratio = _ease(this.cachedTime,0,1,this.cachedDuration);
            }
         }
         if(_loc6_ == 0 && (this.cachedTotalTime != 0 || this.cachedDuration == 0) && !param2)
         {
            if(this.vars.onStart)
            {
               this.vars.onStart.apply(null,this.vars.onStartParams);
            }
            if(_dispatcher)
            {
               _dispatcher.dispatchEvent(new TweenEvent(TweenEvent.START));
            }
         }
         var _loc10_:PropTween = this.cachedPT1;
         while(_loc10_)
         {
            _loc10_.target[_loc10_.property] = _loc10_.start + this.ratio * _loc10_.change;
            _loc10_ = _loc10_.nextNode;
         }
         if(_hasUpdate && !param2)
         {
            this.vars.onUpdate.apply(null,this.vars.onUpdateParams);
         }
         if(_hasUpdateListener && !param2)
         {
            _dispatcher.dispatchEvent(new TweenEvent(TweenEvent.UPDATE));
         }
         if(_loc8_ && !param2 && !this.gc)
         {
            if(this.vars.onRepeat)
            {
               this.vars.onRepeat.apply(null,this.vars.onRepeatParams);
            }
            if(_dispatcher)
            {
               _dispatcher.dispatchEvent(new TweenEvent(TweenEvent.REPEAT));
            }
         }
         if(_loc7_ && !this.gc)
         {
            if(_hasPlugins && this.cachedPT1)
            {
               onPluginEvent("onComplete",this);
            }
            complete(true,param2);
         }
      }
      
      override public function set totalDuration(param1:Number) : void
      {
         if(_repeat == -1)
         {
            return;
         }
         this.duration = (param1 - _repeat * _repeatDelay) / (_repeat + 1);
      }
      
      public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         if(_dispatcher == null)
         {
            initDispatcher();
         }
         if(param1 == TweenEvent.UPDATE)
         {
            _hasUpdateListener = true;
         }
         _dispatcher.addEventListener(param1,param2,param3,param4,param5);
      }
      
      override protected function init() : void
      {
         var _loc1_:TweenMax = null;
         if(this.vars.startAt)
         {
            this.vars.startAt.overwrite = 0;
            this.vars.startAt.immediateRender = true;
            _loc1_ = new TweenMax(this.target,0,this.vars.startAt);
         }
         if(_dispatcher)
         {
            _dispatcher.dispatchEvent(new TweenEvent(TweenEvent.INIT));
         }
         super.init();
         if(_ease in fastEaseLookup)
         {
            _easeType = fastEaseLookup[_ease][0];
            _easePower = fastEaseLookup[_ease][1];
         }
      }
      
      public function removeEventListener(param1:String, param2:Function, param3:Boolean = false) : void
      {
         if(_dispatcher)
         {
            _dispatcher.removeEventListener(param1,param2,param3);
         }
      }
      
      public function setDestination(param1:String, param2:*, param3:Boolean = true) : void
      {
         var _loc4_:Object = {};
         _loc4_[param1] = param2;
         updateTo(_loc4_,!param3);
      }
      
      public function willTrigger(param1:String) : Boolean
      {
         return _dispatcher == null?false:Boolean(_dispatcher.willTrigger(param1));
      }
      
      public function hasEventListener(param1:String) : Boolean
      {
         return _dispatcher == null?false:Boolean(_dispatcher.hasEventListener(param1));
      }
      
      protected function initDispatcher() : void
      {
         if(_dispatcher == null)
         {
            _dispatcher = new EventDispatcher(this);
         }
         if(this.vars.onInitListener is Function)
         {
            _dispatcher.addEventListener(TweenEvent.INIT,this.vars.onInitListener,false,0,true);
         }
         if(this.vars.onStartListener is Function)
         {
            _dispatcher.addEventListener(TweenEvent.START,this.vars.onStartListener,false,0,true);
         }
         if(this.vars.onUpdateListener is Function)
         {
            _dispatcher.addEventListener(TweenEvent.UPDATE,this.vars.onUpdateListener,false,0,true);
            _hasUpdateListener = true;
         }
         if(this.vars.onCompleteListener is Function)
         {
            _dispatcher.addEventListener(TweenEvent.COMPLETE,this.vars.onCompleteListener,false,0,true);
         }
         if(this.vars.onRepeatListener is Function)
         {
            _dispatcher.addEventListener(TweenEvent.REPEAT,this.vars.onRepeatListener,false,0,true);
         }
         if(this.vars.onReverseCompleteListener is Function)
         {
            _dispatcher.addEventListener(TweenEvent.REVERSE_COMPLETE,this.vars.onReverseCompleteListener,false,0,true);
         }
      }
      
      public function set currentProgress(param1:Number) : void
      {
         if(_cyclesComplete == 0)
         {
            setTotalTime(this.duration * param1,false);
         }
         else
         {
            setTotalTime(this.duration * param1 + _cyclesComplete * this.cachedDuration,false);
         }
      }
      
      public function get totalProgress() : Number
      {
         return this.cachedTotalTime / this.totalDuration;
      }
      
      public function set totalProgress(param1:Number) : void
      {
         setTotalTime(this.totalDuration * param1,false);
      }
      
      public function updateTo(param1:Object, param2:Boolean = false) : void
      {
         var _loc4_:* = null;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:PropTween = null;
         var _loc8_:Number = NaN;
         var _loc3_:Number = this.ratio;
         if(param2 && this.timeline != null && this.cachedStartTime < this.timeline.cachedTime)
         {
            this.cachedStartTime = this.timeline.cachedTime;
            this.setDirtyCache(false);
            if(this.gc)
            {
               this.setEnabled(true,false);
            }
            else
            {
               this.timeline.insert(this,this.cachedStartTime - _delay);
            }
         }
         for(_loc4_ in param1)
         {
            this.vars[_loc4_] = param1[_loc4_];
         }
         if(this.initted)
         {
            if(param2)
            {
               this.initted = false;
            }
            else
            {
               if(_notifyPluginsOfEnabled && this.cachedPT1)
               {
                  onPluginEvent("onDisable",this);
               }
               if(this.cachedTime / this.cachedDuration > 0.998)
               {
                  _loc5_ = this.cachedTime;
                  this.renderTime(0,true,false);
                  this.initted = false;
                  this.renderTime(_loc5_,true,false);
               }
               else if(this.cachedTime > 0)
               {
                  this.initted = false;
                  init();
                  _loc6_ = 1 / (1 - _loc3_);
                  _loc7_ = this.cachedPT1;
                  while(_loc7_)
                  {
                     _loc8_ = _loc7_.start + _loc7_.change;
                     _loc7_.change = _loc7_.change * _loc6_;
                     _loc7_.start = _loc8_ - _loc7_.change;
                     _loc7_ = _loc7_.nextNode;
                  }
               }
            }
         }
      }
      
      public function get currentProgress() : Number
      {
         return this.cachedTime / this.duration;
      }
      
      public function get repeat() : int
      {
         return _repeat;
      }
      
      override public function set currentTime(param1:Number) : void
      {
         if(_cyclesComplete != 0)
         {
            if(this.yoyo && _cyclesComplete % 2 == 1)
            {
               param1 = this.duration - param1 + _cyclesComplete * (this.cachedDuration + _repeatDelay);
            }
            else
            {
               param1 = param1 + _cyclesComplete * (this.duration + _repeatDelay);
            }
         }
         setTotalTime(param1,false);
      }
      
      public function get repeatDelay() : Number
      {
         return _repeatDelay;
      }
      
      public function killProperties(param1:Array) : void
      {
         var _loc2_:Object = {};
         var _loc3_:int = param1.length;
         while(--_loc3_ > -1)
         {
            _loc2_[param1[_loc3_]] = true;
         }
         killVars(_loc2_);
      }
      
      public function set repeatDelay(param1:Number) : void
      {
         _repeatDelay = param1;
         setDirtyCache(true);
      }
      
      public function set repeat(param1:int) : void
      {
         _repeat = param1;
         setDirtyCache(true);
      }
      
      override public function complete(param1:Boolean = false, param2:Boolean = false) : void
      {
         super.complete(param1,param2);
         if(!param2 && _dispatcher)
         {
            if(this.cachedTotalTime == this.cachedTotalDuration && !this.cachedReversed)
            {
               _dispatcher.dispatchEvent(new TweenEvent(TweenEvent.COMPLETE));
            }
            else if(this.cachedReversed && this.cachedTotalTime == 0)
            {
               _dispatcher.dispatchEvent(new TweenEvent(TweenEvent.REVERSE_COMPLETE));
            }
         }
      }
      
      override public function invalidate() : void
      {
         this.yoyo = Boolean(this.vars.yoyo == true);
         _repeat = !!this.vars.repeat?int(Number(this.vars.repeat)):0;
         _repeatDelay = !!this.vars.repeatDelay?Number(Number(this.vars.repeatDelay)):Number(0);
         _hasUpdateListener = false;
         if(this.vars.onCompleteListener != null || this.vars.onUpdateListener != null || this.vars.onStartListener != null)
         {
            initDispatcher();
         }
         setDirtyCache(true);
         super.invalidate();
      }
      
      public function get timeScale() : Number
      {
         return this.cachedTimeScale;
      }
      
      override public function get totalDuration() : Number
      {
         if(this.cacheIsDirty)
         {
            this.cachedTotalDuration = _repeat == -1?Number(999999999999):Number(this.cachedDuration * (_repeat + 1) + _repeatDelay * _repeat);
            this.cacheIsDirty = false;
         }
         return this.cachedTotalDuration;
      }
   }
}
