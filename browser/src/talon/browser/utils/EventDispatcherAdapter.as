package talon.browser.utils
{
	import flash.utils.Dictionary;
	import starling.errors.AbstractMethodError;
	import starling.events.Event;
	import starling.events.EventDispatcher;

	public class EventDispatcherAdapter extends EventDispatcher
	{
		private var _target:EventDispatcher;
		private var _listeners:Dictionary;

		public function EventDispatcherAdapter()
		{
			_listeners = new Dictionary();
		}

		public override function addEventListener(type:String, listener:Function):void
		{
			var listeners:Vector.<Function> = _listeners[type] || (_listeners[type] = new Vector.<Function>());
			var indexOf:int = listeners.indexOf(listener);
			if (indexOf == -1)
			{
				listeners.push(listener);
				_target && _target.addEventListener(type, listener);
			}
		}

		public override function removeEventListener(type:String, listener:Function):void
		{
			var listeners:Vector.<Function> = _listeners[type];
			if (listeners)
			{
				var indexOf:int = listeners.indexOf(listener);
				if (indexOf != -1)
				{
					listeners.splice(indexOf, 1);
					_target && _target.removeEventListener(type, listener);
				}
			}
		}

		public override function removeEventListeners(type:String = null):void
		{
			_target && _target.removeEventListeners(type);
			delete _listeners[type];
		}

		public override function dispatchEvent(event:Event):void { throw new AbstractMethodError("Not allowed"); }
		public override function dispatchEventWith(type:String, bubbles:Boolean = false, data:Object = null):void { throw new AbstractMethodError("Not allowed"); }
		public override function hasEventListener(type:String):Boolean { return _listeners[type] && _listeners[type].length>0; }

		private function refresh(attach:Boolean):void
		{
			for (var type:String in _listeners)
			{
				var listeners:Vector.<Function> = _listeners[type];
				for each (var listener:Function in listeners)
					attach ? _target.addEventListener(type, listener) : _target.removeEventListener(type, listener);
			}
		}

		public function get target():EventDispatcher { return _target; }
		public function set target(value:EventDispatcher):void
		{
			if (_target != value)
			{
				_target && refresh(false);
				_target = value;
				_target && refresh(true);
			}
		}
	}
}
