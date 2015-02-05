package designer.utils
{
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	public class Settings extends EventDispatcher
	{
		private var _data:Object = new Object();
		private var _listeners:Dictionary = new Dictionary();

		public function addSettingListener(name:String, listener:Function):void
		{
			_listeners[listener] = function (e:Event):void
			{
				if (e.data == name)
				{
					listener(e);
				}
			};

			addEventListener(Event.CHANGE, _listeners[listener]);
		}

		public function removeSettingListener(name:String, listener:Function):void
		{
			removeEventListener(Event.CHANGE, _listeners[listener]);
		}

		public function getValueOrDefault(name:String, initial:* = null):*
		{
			return _data.hasOwnProperty(name) ? _data[name] : initial;
		}

		public function setValue(name:String, value:*):void
		{
			if (_data[name] != value)
			{
				_data[name] = value;
				dispatchEventWith(Event.CHANGE, false, name);
			}
		}
	}
}