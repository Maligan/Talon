package browser.utils
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	public class Storage extends EventDispatcher
	{
		public static function fromSharedObject(sharedObjectName:String):Storage
		{
			var storage:Storage = new Storage();
			var sharedObject:SharedObject = SharedObject.getLocal(sharedObjectName);
			storage._inner = sharedObject.data;
			storage._flush = sharedObject.flush;
			return storage;
		}

		public static function fromPropertiesFile(file:File):Storage
		{
			var storage:Storage = new Storage();
			var bytes:ByteArray = readFile(file);
			var string:String = bytes.toString();
			storage._inner = parse(string);
			return storage;
		}

		private static function readFile(file:File):ByteArray
		{
			var result:ByteArray = new ByteArray();
			var stream:FileStream = new FileStream();

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

		/** Simple Properties file format parser. */
		private static function parse(string:String):Object
		{
			var result:Object = new Object();
			var values:Array = string.split(/[\n\r]/);
			var pattern:RegExp = /\s*([\w\.]+)\s*\=\s*(.*)\s*$/;

			for each (var line:String in values)
			{
				var property:Array = pattern.exec(line);
				if (property)
				{
					var key:String = property[1];
					var value:String = property[2];
					result[key] = value;
				}
			}

			return result;
		}

		private var _listeners:Dictionary;
		private var _inner:Object;
		private var _flush:Function;

		public function Storage():void
		{
			_listeners = new Dictionary();
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

		public function getValueOrDefault(name:String, type:Class, value:* = null):*
		{
			return _inner.hasOwnProperty(name) ? (_inner[name] as type) : value;
		}

		public function setValue(name:String, value:*):void
		{
			_inner[name] = value;
			_flush && _flush();
			dispatchEventWith(Event.CHANGE, false, name);
		}
	}
}