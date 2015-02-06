package browser.utils
{
	import flash.net.SharedObject;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	public class Settings extends EventDispatcher
	{
		private var _data:Object;
		private var _listeners:Dictionary = new Dictionary();
		private var _storage:SharedObject;

		public function Settings(name:String):void
		{
			_storage = SharedObject.getLocal(name);
			_data = _storage.data;
		}

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
				_storage.flush();
				dispatchEventWith(Event.CHANGE, false, name);
			}
		}
	}
}