package com.doitflash.events
{
   import flash.events.Event;
   
   public class ScrollEvent extends Event
   {
      public static const MOUSE_MOVE:String = "onMouseMove";
      public static const TOUCH_TWEEN_COMPLETE:String = "touchTweenComplete";
      public static const MOUSE_UP:String = "onMouseUp";
      public static const MOUSE_DOWN:String = "onMouseDown";
      public static const TOUCH_TWEEN_UPDATE:String = "touchTweenUpdate";
      
      private var _param;
      
      public function ScrollEvent(param1:String, param2:* = null, param3:Boolean = false, param4:Boolean = false)
      {
         _param = param2;
         super(param1,param3,param4);
      }
      
      public function get param() : *
      {
         return _param;
      }
   }
}
