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

		private var _cacheBytes:ByteArray;
		private var _cacheBytesAsXML:XML;
		private var _cacheError:Error;

		public function DesktopFileReference(target:File, root:File)
		{
			if (!target) throw new ArgumentError("File must be non null");
			if (!root) throw new ArgumentError("Root must be non null");

			_root = root;
			_target = target;
			_monitor = new FileMonitor(_target);
			_monitor.addEventListener(Event.CHANGE, onFileChange);
			_monitor.watch();
		}

		private function onFileChange(e:*):void
		{
			_cacheBytes && _cacheBytes.clear();
			_cacheBytes = null;
			_cacheBytesAsXML && System.disposeXML(_cacheBytesAsXML);
			_cacheBytesAsXML = null;
			_cacheError = null;

			dispatchEvent(new Event(Event.CHANGE));
		}

		//
		// Format definition methods
		//
		public function checkFirstMeaningfulChar(char:String):Boolean
		{
			if (cacheBytes == null) return false;
			var starts:Boolean = byteArrayStartsWith(cacheBytes, char);

			return starts;
		}

		public function checkSignature(signature:String):Boolean
		{
			if (cacheBytes == null) return false;
			if (cacheBytes.bytesAvailable < signature.length) return false;

			for (var i:int = 0; i < signature.length; i++)
			{
				if (signature.charCodeAt(i) != cacheBytes[i]) return false;
			}

			return true;
		}
		public function get extension():String
		{
			var matches:Array = NAME_REGEX.exec(path);
			if (matches && matches.length > 0) return matches[2];
			else return null;
		}

		//
		// IFileReference
		//
		public function get path():String { return root.getRelativePath(target) + (target.isDirectory ? "/" : ""); }

		public function get data():ByteArray { return _target.exists ? cacheBytes : null; }

		//
		// Properties
		//
		public function get target():File { return _target; }

		public function get root():File { return _root; }

		public function get cacheBytes():ByteArray { return _cacheBytes ||= readBytes(); }

		public function get cacheBytesAsXML():XML { return _cacheBytesAsXML ||= readXML(); }

		public function get cacheError():Error { return _cacheError; }

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
				_cacheError = e;
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
			try { return new XML(cacheBytes); }
			catch (e:Error) { return null; }
		}
	}
}