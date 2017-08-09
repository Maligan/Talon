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
		public static function getFileReferencePath(target:File, root:File, rootPrefix:String):String
		{
			if (target == null || root == null) return null;

			var result:String = root.getRelativePath(target);

			if (rootPrefix && result)
				result = rootPrefix + "/" + result;
			else if (rootPrefix)
				result = rootPrefix;

			if (target.isDirectory)
				result += "/";

			return result;
		}

		private static const NAME_REGEX:RegExp = /([^\?\/\\]+?)(?:\.([\w\-]+))?(?:\?.*)?$/;

		private var _root:File;
		private var _rootPrefix:String;
		private var _monitor:FileMonitor;

		private var _cacheName:Array;
		private var _cachePath:String;
		private var _cacheBytes:ByteArray;
		private var _cacheXML:XML;
		private var _cacheError:Error;

		public function DesktopFileReference(target:File, root:File, rootPrefix:String = null)
		{
			_monitor = new FileMonitor();
			_monitor.addEventListener(Event.CHANGE, onFileChange);
			_monitor.watch();
			
			reset(target, root, rootPrefix);
		}

		private function onFileChange(e:*):void
		{
			clearCache();
			dispatchEvent(new Event(Event.CHANGE));
		}

		private function reset(target:File, root:File, rootPrefix:String):void
		{
			clearCache();

			_root = root;
			_rootPrefix = rootPrefix ? rootPrefix.replace(/\/$/, "") : "";
			_monitor.file = target;
			_cachePath = getFileReferencePath(target, root, rootPrefix);
			_cacheName = NAME_REGEX.exec(_cachePath) || [];
		}

		private function clearCache():void
		{
			_cacheBytes && _cacheBytes.clear();
			_cacheBytes = null;
			_cacheXML && System.disposeXML(_cacheXML);
			_cacheXML = null;
			_cacheError = null;
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

		public function get name():String { return _cacheName[0]; }
		public function get nameWithoutExtension():String { return _cacheName[1]; }
		public function get extension():String { return _cacheName[2] || ""; }

		//
		// IFileReference
		//
		public function get path():String { return _cachePath; }

		public function get data():ByteArray { return target.exists ? cacheBytes : null; }

		public function dispose():void { reset(null, null, null) }

		//
		// Properties
		//
		public function get target():File { return _monitor.file; }

		public function get root():File { return _root; }

		public function get rootPrefix():String { return _rootPrefix; }

		public function get cacheBytes():ByteArray { return _cacheBytes ||= readBytes(); }

		public function get cacheXML():XML { return _cacheXML ||= readXML(); }

		public function get cacheError():Error { return _cacheError; }

		//
		// Read
		//
		private function readBytes():ByteArray
		{
			var result:ByteArray = new ByteArray();
			var stream:FileStream = new FileStream();

			try
			{
				stream.open(target, FileMode.READ);
				stream.readBytes(result, 0, stream.bytesAvailable);
			}
			catch (e:Error)
			{
				_cacheError = e;
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