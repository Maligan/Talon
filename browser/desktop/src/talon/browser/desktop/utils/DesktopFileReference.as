package talon.browser.desktop.utils
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.System;
	import flash.utils.ByteArray;

	import talon.browser.platform.document.files.IFileReference;
	import talon.browser.platform.utils.byteArrayStartsWith;

	[Event(name="change", type="flash.events.Event")]
	public class DesktopFileReference extends EventDispatcher implements IFileReference
	{
		private static const NAME_REGEX:RegExp = /([^\?\/\\]+?)(?:\.([\w\-]+))?(?:\?.*)?$/;

		private var _root:File;
		private var _target:File;
		private var _monitor:FileMonitor;
		private var _bytes:ByteArray;
		private var _xml:XML;

		public function DesktopFileReference(target:File, root:File)
		{
			if (!target) throw new ArgumentError("File must be non null");

			_root = root;
			_target = target;
			_monitor = new FileMonitor(_target);
			_monitor.addEventListener(Event.CHANGE, onFileChange);
			_monitor.watch();
		}

		private function onFileChange(e:*):void
		{
			_bytes && _bytes.clear();
			_bytes = null;
			_xml && System.disposeXML(_xml);
			_xml = null;

			dispatchEvent(new Event(Event.CHANGE));
		}

		public function checkFirstMeaningfulChar(char:String):Boolean
		{
			if (bytes == null) return false;
			var starts:Boolean = byteArrayStartsWith(bytes, char);

			return starts;
		}

		public function checkSignature(signature:String):Boolean
		{
			if (bytes == null) return false;
			if (bytes.bytesAvailable < signature.length) return false;

			for (var i:int = 0; i < signature.length; i++)
			{
				if (signature.charCodeAt(i) != bytes[i]) return false;
			}

			return true;
		}

		//
		// Names
		//
		public function get url():String
		{
			return _target.url;
		}

		public function get extension():String
		{
			var matches:Array = NAME_REGEX.exec(url);
			if (matches && matches.length > 0) return matches[2];
			else return null;
		}

		//
		// IFileReference
		//
		public function get path():String { return root.getRelativePath(target) + (target.isDirectory ? "/" : ""); }

		public function get data():ByteArray { return _target.exists ? bytes : null; }

		//
		// Properties
		//
		public function get target():File { return _target; }

		public function get root():File { return _root; }

		public function get bytes():ByteArray
		{
			if (_bytes == null)
				_bytes = readBytes();

			return _bytes;
		}

		public function get xml():XML
		{
			if (_xml == null)
				_xml = readXML();

			return _xml;
		}

		//
		// Read
		//
		private function readBytes():ByteArray
		{
			var result:ByteArray = null;
			var stream:FileStream = new FileStream();

			try
			{
				result = new ByteArray();
				stream.open(_target, FileMode.READ);
				stream.readBytes(result, 0, stream.bytesAvailable);
			}
			catch (e:Error)
			{
				result = new ByteArray();
			}
			finally
			{
				stream.close();
				return result;
			}
		}

		private function readXML():XML
		{
			var bytes:ByteArray = readBytes();

			try
			{
				return new XML(bytes);
			}
			catch (e:Error)
			{
				return null;
			}
		}
	}
}