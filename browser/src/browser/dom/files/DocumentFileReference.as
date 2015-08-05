package browser.dom.files
{
	import browser.dom.Document;
	import browser.dom.log.DocumentMessage;
	import browser.utils.Glob;

	import com.adobe.air.filesystem.FileMonitor;
	import com.adobe.air.filesystem.events.FileMonitorEvent;

	import browser.AppConstants;

	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.System;
	import flash.utils.ByteArray;

	import starling.events.EventDispatcher;

	[Event(name="change", type="starling.events.Event")]
	public class DocumentFileReference extends EventDispatcher
	{
		private var _document:Document;
		private var _target:File;
		private var _monitor:FileMonitor;
		private var _type:String;

		public function DocumentFileReference(document:Document, target:File)
		{
			if (!document) throw new ArgumentError("Document must be non null");
			if (!target) throw new ArgumentError("File must be non null");

			_document = document;
			_target = target;
			_monitor = new FileMonitor(_target);
			_monitor.addEventListener(FileMonitorEvent.CHANGE, onFileChange);
			_monitor.addEventListener(FileMonitorEvent.MOVE, onFileChange);
			_monitor.addEventListener(FileMonitorEvent.CREATE, onFileChange);
			_monitor.watch();
		}

		private function onFileChange(e:FileMonitorEvent):void
		{
			_type = null;
			dispatchEventWith(Event.CHANGE);
		}

		public function readBytes():ByteArray
		{
			if (!exists) throw new ArgumentError("File not exists");

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

		public function readXML():XML
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

		/** @see browser.dom.files.DocumentFileType */
		public function get type():String
		{
			return _type || (_type = getType());
		}

		private function getType():String
		{
			if (extension == "css") return DocumentFileType.STYLE;
			if (extension == "xml")
			{
				var xml:XML = readXML();
				if (xml != null)
				{
					var root:String = xml.name();
					System.disposeXML(xml);

					if (root == "template") return DocumentFileType.TEMPLATE;
					if (root == "library") return DocumentFileType.LIBRARY;
					if (root == "TextureAtlas") return DocumentFileType.ATLAS;
				}

				return DocumentFileType.UNKNOWN;
			}
			if (extension == "fnt") return DocumentFileType.BITMAP_FONT;
			if (AppConstants.SUPPORTED_IMAGE_EXTENSIONS.indexOf(extension) != -1) return DocumentFileType.IMAGE;
			if (_target.isDirectory) return DocumentFileType.DIRECTORY;

			return DocumentFileType.UNKNOWN;
		}

		private function get extension():String
		{
			var extensionDotIndex:int = url.lastIndexOf('.');
			if (extensionDotIndex != -1) return url.substring(extensionDotIndex + 1);
			return null;
		}

		/** Unique reference url. */
		public function get url():String { return _target.url; }
		public function get exists():Boolean { return _target.exists; }
		public function get document():Document { return _document; }

		/** @private For internal usage ONLY. */
		public function get target():File
		{
			return _target;
		}

		/** File is ignored for export. */
		public function get isIgnored():Boolean
		{
			if (type == DocumentFileType.DIRECTORY) return true;
			if (type == DocumentFileType.UNKNOWN) return true;

			var result:Boolean = false;
			var property:String = document.properties.getValueOrDefault(AppConstants.PROPERTY_EXPORT_IGNORE);
			if (property == null) return false;
			var spilt:Array = property.split(/\s*,\s*/);

			for each (var pattern:String in spilt)
			{
 				var glob:Glob = new Glob(pattern);
				if (glob.match(exportPath))
				{
					result = !glob.invert;
					if (result == false) break;
				}
			}

			return result;
		}

		public function get exportPath():String
		{
			var sourcePathProperty:String = document.properties.getValueOrDefault(AppConstants.PROPERTY_SOURCE_PATH);
			var sourcePath:File = document.project.parent.resolvePath(sourcePathProperty || document.project.parent.nativePath);
			if (sourcePath.exists == false) sourcePath = document.project.parent;
			return sourcePath.getRelativePath(target);
		}
	}
}