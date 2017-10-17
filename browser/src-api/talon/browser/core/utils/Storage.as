package talon.browser.core.utils
{
	import flash.net.SharedObject;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	import talon.utils.OrderedObject;
	import talon.utils.ParseUtil;

	public class Storage extends EventDispatcher
	{
		public static function fromSharedObject(sharedObjectName:String):Storage
		{
			var storage:Storage = new Storage();

			try
			{
				// There is may be problems while refactoring:
				// Try move DeviceProfile to another package and after restart application

				var sharedObject:SharedObject = SharedObject.getLocal(sharedObjectName);
				storage._inner = sharedObject.data;
				storage._flush = sharedObject.flush;
			}
			catch (e:Error)
			{
				storage._inner = { };
			}

			return storage;
		}
		
		public static function fromProperties(properties:String):Storage
		{
			var storage:Storage = new Storage();
			storage._inner = ParseUtil.parseProperties(properties, new OrderedObject());
			return storage;
		}

		private var _listeners:Dictionary;
		private var _inner:Object;
		private var _flush:Function;

		public function Storage():void
		{
			_listeners = new Dictionary();
			_inner = {};
		}
		
		public function dispose():void
		{
			// For override
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

		public function getValue(name:String, type:Class = null, value:* = null):*
		{
			return _inner.hasOwnProperty(name) ? (type ? _inner[name] as type : _inner[name]) : value;
		}

		public function setValue(name:String, value:*):void
		{
			_inner[name] = value;
			_flush && _flush();
			dispatchEventWith(Event.CHANGE, false, name);
		}

		public function getNames(prefix:String = ""):Vector.<String>
		{
			var names:Vector.<String> = new <String>[];

			for (var name:String in _inner)
				if (name.indexOf(prefix) == 0)
					names[names.length] = name;

			return names;
		}
	}
}