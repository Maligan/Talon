package browser.utils
{
	import flash.net.SharedObject;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	public class Storage extends EventDispatcher
	{
		private var _listeners:Dictionary = new Dictionary();
		private var _sharedObject:SharedObject;

		public function Storage(name:String):void
		{
			_sharedObject = SharedObject.getLocal(name);
		}

		public function addPropertyListener(name:String, listener:Function):void
		{
			_listeners[listener] = function (e:Event):void
			{
				if (e.data == name)
				{
					listener.length
						? listener(e)
						: listener();
				}
			};

			addEventListener(Event.CHANGE, _listeners[listener]);
		}

		public function removePropertyListener(name:String, listener:Function):void
		{
			removeEventListener(Event.CHANGE, _listeners[listener]);
		}

		public function getValueOrDefault(name:String, initial:* = null):*
		{
			return _sharedObject.data.hasOwnProperty(name) ? _sharedObject.data[name] : initial;
		}

		public function setValue(name:String, value:*):void
		{
			_sharedObject.data[name] = value;
			_sharedObject.flush();
			dispatchEventWith(Event.CHANGE, false, name);
		}
	}
}