package com.greensock.plugins
{
   import com.greensock.TweenLite;
   
   public class ThrowPropsPlugin extends TweenPlugin
   {
      
      public static var defaultResistance:Number = 100;
      
      public static const API:Number = 1;
       
      
      protected var _props:Array;
      
      protected var _target:Object;
      
      protected var _tween:TweenLite;
      
      public function ThrowPropsPlugin()
      {
         super();
         this.propName = "throwProps";
         this.overwriteProps = [];
      }
      
      public static function calculateTweenDuration(param1:Object, param2:Object, param3:Number = 100, param4:Number = 0.25, param5:Number = 1) : Number
      {
         var _loc12_:Object = null;
         var _loc13_:Number = NaN;
         var _loc14_:Number = NaN;
         var _loc15_:Number = NaN;
         var _loc16_:Number = NaN;
         var _loc17_:Number = NaN;
         var _loc18_:* = null;
         var _loc6_:Number = 0;
         var _loc7_:Number = 9999999999;
         var _loc8_:Object = "throwProps" in param2?param2.throwProps:param2;
         var _loc9_:Function = param2.ease is Function?param2.ease:_easeOut;
         var _loc10_:Number = "checkpoint" in _loc8_?Number(Number(_loc8_.checkpoint)):Number(0.05);
         var _loc11_:Number = "resistance" in _loc8_?Number(Number(_loc8_.resistance)):Number(defaultResistance);
         for(_loc18_ in _loc8_)
         {
            if(_loc18_ != "resistance" && _loc18_ != "checkpoint")
            {
               _loc12_ = _loc8_[_loc18_];
               if(typeof _loc12_ == "number")
               {
                  _loc14_ = Number(_loc12_);
                  _loc13_ = _loc14_ * _loc11_ > 0?Number(_loc14_ / _loc11_):Number(_loc14_ / -_loc11_);
               }
               else
               {
                  _loc14_ = Number(Number(_loc12_.velocity)) || Number(0);
                  _loc15_ = "resistance" in _loc12_?Number(Number(_loc12_.resistance)):Number(_loc11_);
                  _loc13_ = _loc14_ * _loc15_ > 0?Number(_loc14_ / _loc15_):Number(_loc14_ / -_loc15_);
                  _loc16_ = param1[_loc18_] + calculateChange(_loc14_,_loc9_,_loc13_,_loc10_);
                  if("max" in _loc12_ && _loc16_ > Number(_loc12_.max))
                  {
                     _loc17_ = param1[_loc18_] > _loc12_.max || _loc14_ > -15 && _loc14_ < 45?Number(0.75):Number(calculateDuration(param1[_loc18_],_loc12_.max,_loc14_,_loc9_,_loc10_));
                     if(_loc17_ + param5 < _loc7_)
                     {
                        _loc7_ = _loc17_ + param5;
                     }
                  }
                  else if("min" in _loc12_ && _loc16_ < Number(_loc12_.min))
                  {
                     _loc17_ = param1[_loc18_] < _loc12_.min || _loc14_ > -45 && _loc14_ < 15?Number(0.75):Number(calculateDuration(param1[_loc18_],_loc12_.min,_loc14_,_loc9_,_loc10_));
                     if(_loc17_ + param5 < _loc7_)
                     {
                        _loc7_ = _loc17_ + param5;
                     }
                  }
                  if(_loc17_ > _loc6_)
                  {
                     _loc6_ = _loc17_;
                  }
               }
               if(_loc13_ > _loc6_)
               {
                  _loc6_ = _loc13_;
               }
            }
         }
         if(_loc6_ > _loc7_)
         {
            _loc6_ = _loc7_;
         }
         if(_loc6_ > param3)
         {
            return param3;
         }
         if(_loc6_ < param4)
         {
            return param4;
         }
         return _loc6_;
      }
      
      public static function to(param1:Object, param2:Object, param3:Number = 100, param4:Number = 0.25, param5:Number = 1) : TweenLite
      {
         if(!("throwProps" in param2))
         {
            param2 = {"throwProps":param2};
         }
         return new TweenLite(param1,calculateTweenDuration(param1,param2,param3,param4,param5),param2);
      }
      
      public static function calculateChange(param1:Number, param2:Function, param3:Number, param4:Number = 0.05) : Number
      {
         return param3 * param4 * param1 / param2(param4,0,1,1);
      }
      
      protected static function _easeOut(param1:Number, param2:Number, param3:Number, param4:Number) : Number
      {
         return 1 - (param1 = 1 - param1 / param4) * param1;
      }
      
      public static function calculateDuration(param1:Number, param2:Number, param3:Number, param4:Function, param5:Number = 0.05) : Number
      {
         return Math.abs((param2 - param1) * param4(param5,0,1,1) / param3 / param5);
      }
      
      override public function killProps(param1:Object) : void
      {
         var _loc2_:int = _props.length;
         while(_loc2_--)
         {
            if(_props[_loc2_].property in param1)
            {
               _props.splice(_loc2_,1);
            }
         }
         super.killProps(param1);
      }
      
      override public function onInitTween(param1:Object, param2:*, param3:TweenLite) : Boolean
      {
         var _loc6_:* = null;
         var _loc7_:Object = null;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc11_:Number = NaN;
         _target = param1;
         _tween = param3;
         _props = [];
         var _loc4_:Function = _tween.vars.ease is Function?_tween.vars.ease:_easeOut;
         var _loc5_:Number = "checkpoint" in param2?Number(Number(param2.checkpoint)):Number(0.05);
         var _loc12_:Number = _tween.cachedDuration;
         var _loc13_:uint = 0;
         for(_loc6_ in param2)
         {
            if(_loc6_ != "resistance" && _loc6_ != "checkpoint")
            {
               _loc7_ = param2[_loc6_];
               if(typeof _loc7_ == "number")
               {
                  _loc8_ = Number(_loc7_);
               }
               else if("velocity" in _loc7_)
               {
                  _loc8_ = Number(_loc7_.velocity);
               }
               else
               {
                  trace("ERROR: No velocity was defined in the throwProps tween of " + param1 + " property: " + _loc6_);
                  _loc8_ = 0;
               }
               _loc9_ = calculateChange(_loc8_,_loc4_,_loc12_,_loc5_);
               _loc11_ = 0;
               if(typeof _loc7_ != "number")
               {
                  _loc10_ = _target[_loc6_] + _loc9_;
                  if("max" in _loc7_ && Number(_loc7_.max) < _loc10_)
                  {
                     _loc11_ = _loc7_.max - _target[_loc6_] - _loc9_;
                  }
                  else if("min" in _loc7_ && Number(_loc7_.min) > _loc10_)
                  {
                     _loc11_ = _loc7_.min - _target[_loc6_] - _loc9_;
                  }
               }
               _props[_loc13_++] = new ThrowProp(_loc6_,Number(param1[_loc6_]),_loc9_,_loc11_);
               this.overwriteProps[_loc13_] = _loc6_;
            }
         }
         return true;
      }
      
      override public function set changeFactor(param1:Number) : void
      {
         var _loc3_:ThrowProp = null;
         var _loc4_:Number = NaN;
         var _loc2_:int = _props.length;
         if(!this.round)
         {
            while(_loc2_--)
            {
               _loc3_ = _props[_loc2_];
               _target[_loc3_.property] = _loc3_.start + _loc3_.change1 * param1 + _loc3_.change2 * param1 * param1;
            }
         }
         else
         {
            while(_loc2_--)
            {
               _loc3_ = _props[_loc2_];
               _loc4_ = _loc3_.start + _loc3_.change1 * param1 + _loc3_.change2 * param1 * param1;
               _target[_loc3_.property] = _loc4_ >= 0?_loc4_ + 0.5 >> 0:_loc4_ - 0.5 >> 0;
            }
         }
      }
   }
}

class ThrowProp
{
    
   
   public var change1:Number;
   
   public var start:Number;
   
   public var property:String;
   
   public var change2:Number;
   
   function ThrowProp(param1:String, param2:Number, param3:Number, param4:Number)
   {
      super();
      this.property = param1;
      this.start = param2;
      this.change1 = param3;
      this.change2 = param4;
   }
}
