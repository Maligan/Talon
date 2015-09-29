package browser.document.files
{
	import avmplus.finish;

	import browser.document.Document;
	import browser.utils.byteArrayStartsWith;

	import browser.utils.FileMonitor;

	import browser.AppConstants;

	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	import starling.events.EventDispatcher;

	[Event(name="change", type="starling.events.Event")]
	public class DocumentFileReference extends EventDispatcher
	{
		private static const NAME_REGEX:RegExp = /([^\?\/\\]+?)(?:\.([\w\-]+))?(?:\?.*)?$/;

		private var _document:Document;
		private var _target:File;
		private var _monitor:FileMonitor;
		private var _bytes:ByteArray;
		private var _xml:XML;

		public function DocumentFileReference(document:Document, target:File)
		{
			if (!document) throw new ArgumentError("Document must be non null");
			if (!target) throw new ArgumentError("File must be non null");

			_document = document;
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

			dispatchEventWith(Event.CHANGE);
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

		public function get basename():String
		{
			var matches:Array = NAME_REGEX.exec(url);
			if (matches && matches.length > 0) return matches[1];
			else return null;
		}

		public function get extension():String
		{
			var matches:Array = NAME_REGEX.exec(url);
			if (matches && matches.length > 0) return matches[2];
			else return null;
		}

		public function get exportPath():String
		{
			var sourcePathProperty:String = document.properties.getValueOrDefault(AppConstants.PROPERTY_SOURCE_PATH, String);
			var sourcePath:File = document.project.parent.resolvePath(sourcePathProperty || document.project.parent.nativePath);
			if (sourcePath.exists == false) sourcePath = document.project.parent;
			return sourcePath.getRelativePath(target);
		}

		//
		// Properties
		//
		public function get exists():Boolean { return _target.exists; }

		public function get document():Document { return _document; }

		/** @private For internal usage ONLY. */
		public function get target():File { return _target; }

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
//			if (!exists) throw new ArgumentError("File not exists: ", url);
			if (!exists) new ByteArray();

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
				result = null;
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