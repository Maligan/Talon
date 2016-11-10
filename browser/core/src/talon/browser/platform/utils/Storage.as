package talon.browser.platform.utils
{
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	import talon.utils.ParseUtil;

	public class Storage extends EventDispatcher
	{
		public static function fromSharedObject(sharedObjectName:String):Storage
		{
			var storage:Storage = new Storage();

			try
			{
				// FIXME: Error with class aliases, refactoring
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

		public static function fromPropertiesFile(file:*):Storage
		{
			var storage:Storage = new Storage();
			var bytes:ByteArray = readFile(file);
			var string:String = bytes.toString();
			storage._inner = ParseUtil.parseProperties(string);
			return storage;
		}

		private static function readFile(file:*):ByteArray
		{
			const FileStream:Class = getDefinitionByName("flash.filesystem.FileStream") as Class;
			const FileMode:Class = getDefinitionByName("flash.filesystem.FileMode") as Class;

			var result:ByteArray = new ByteArray();
			var stream:* = new FileStream();

			try
			{
				stream.open(file, FileMode.READ);
				stream.readBytes(result, 0, stream.bytesAvailable);
			}
			finally
			{
				stream.close();
			}

			return result;
		}

		private var _listeners:Dictionary;
		private var _inner:Object;
		private var _flush:Function;

		public function Storage():void
		{
			_listeners = new Dictionary();
			_inner = {};
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

		public function getValueOrDefault(name:String, type:Class = null, value:* = null):*
		{
			return _inner.hasOwnProperty(name) ? (type ? _inner[name] as type : _inner[name]) : value;
		}

		public function setValue(name:String, value:*):void
		{
			_inner[name] = value;
			_flush && _flush();
			dispatchEventWith(Event.CHANGE, false, name);
		}
	}
}