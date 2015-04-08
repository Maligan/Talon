package browser.dom.files
{
	import browser.dom.Document;
	import browser.utils.parseGlob;

	import com.adobe.air.filesystem.FileMonitor;
	import com.adobe.air.filesystem.events.FileMonitorEvent;

	import browser.utils.Constants;

	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	import starling.events.EventDispatcher;

	[Event(name="change", type="starling.events.Event")]
	public class DocumentFileReference extends EventDispatcher
	{
		private var _document:Document;
		private var _file:File;
		private var _monitor:FileMonitor;
		private var _type:String;

		public function DocumentFileReference(document:Document, file:File)
		{
			if (!document) throw new ArgumentError("Document must be non null");
			if (!file) throw new ArgumentError("File must be non null");
			if (!file.exists) throw new ArgumentError("File must be exists");

			_document = document;
			_file = file;
			_monitor = new FileMonitor(_file);
			_monitor.addEventListener(FileMonitorEvent.CHANGE, onFileChange);
			_monitor.addEventListener(FileMonitorEvent.MOVE, onFileChange);
			_monitor.addEventListener(FileMonitorEvent.CREATE, onFileChange);
			_monitor.watch();
		}

		private function onFileChange(e:FileMonitorEvent):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public function read():ByteArray
		{
			if (!exits) throw new ArgumentError("File not exists");

			var result:ByteArray = new ByteArray();
			var stream:FileStream = new FileStream();

			try
			{
				stream.open(_file, FileMode.READ);
				stream.readBytes(result, 0, stream.bytesAvailable);
			}
			finally
			{
				stream.close();
			}

			return result;
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
				var xml:XML = new XML(read());
				var root:String = xml.name();
				if (root == "template") return DocumentFileType.TEMPLATE;
				if (root == "library") return DocumentFileType.LIBRARY;
				if (root == "TextureAtlas") return DocumentFileType.ATLAS;
				return DocumentFileType.UNKNOWN;
			}
			if (extension == "fnt") return DocumentFileType.FONT;
			if (Constants.SUPPORTED_IMAGE_EXTENSIONS.indexOf(extension) != -1) return DocumentFileType.IMAGE;
			if (_file.isDirectory) return DocumentFileType.DIRECTORY;

			return DocumentFileType.UNKNOWN;
		}

		private function get extension():String
		{
			var extensionDosIndex:int = url.lastIndexOf('.');
			if (extensionDosIndex != -1) return url.substring(extensionDosIndex + 1);
			return null;
		}

		public function equals(reference:DocumentFileReference):Boolean
		{
			return reference != null
				&& reference.url == url;
		}

		public function get url():String
		{
			return _file.url;
		}

		public function get exits():Boolean
		{
			return _file.exists;
		}

		public function get document():Document
		{
			return _document;
		}

		/** @private For internal usage ONLY. */
		public function get file():File
		{
			return _file;
		}

		/** File is ignored for export. */
		public function get isIgnored():Boolean
		{
			if (type == DocumentFileType.DIRECTORY) return true;
			if (type == DocumentFileType.UNKNOWN) return true;

			var ignored:Boolean = false;
			var ignoresProperty:String = document.properties[Constants.PROPERTY_EXPORT_IGNORE];
			if (ignoresProperty)
			{
				var spilt:Array = ignoresProperty.split(/\s*,\s*/);
				for each (var glob:String in spilt)
				{
					var isNegative:Boolean = glob.charAt(0) == "!";
					if (isNegative) glob = glob.substring(1);
					var isMatch:Boolean = parseGlob(glob).test(exportPath);

					if (isMatch &&  isNegative) return false;
					if (isMatch && !isNegative) ignored = true;
				}
			}

			return ignored;
		}

		public function get exportPath():String
		{
			var sourcePathProperty:String = document.properties[Constants.PROPERTY_SOURCE_PATH];
			var sourcePath:File = document.file.parent.resolvePath(sourcePathProperty || document.file.parent.nativePath);
			if (sourcePath.exists == false) sourcePath = document.file.parent;
			return sourcePath.getRelativePath(file);
		}
	}
}