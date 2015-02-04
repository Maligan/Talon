package designer.dom.files
{
	import com.adobe.air.filesystem.FileMonitor;
	import com.adobe.air.filesystem.events.FileMonitorEvent;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	import starling.events.EventDispatcher;

	[Event(name="change", type="starling.events.Event")]
	public class DocumentFileReference extends EventDispatcher
	{
		private var _file:File;
		private var _monitor:FileMonitor;
		private var _type:String;

		public function DocumentFileReference(file:File)
		{
			if (!file) throw new ArgumentError("File must be non null");
			if (!file.exists) throw new ArgumentError("File must be exists");

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

		/** @see designer.dom.files.DocumentFileType */
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
				if (root == "prototype") return DocumentFileType.PROTOTYPE;
				if (root == "TextureAtlas") return DocumentFileType.ATLAS;
				return DocumentFileType.UNKNOWN;
			}
			if (extension == "fnt") return DocumentFileType.FONT;
			if (DesignerConstants.SUPPORTED_IMAGE_EXTENSIONS.indexOf(extension) != -1) return DocumentFileType.IMAGE;
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

		/** @private For internal usage ONLY. */
		public function get file():File
		{
			return _file;
		}
	}
}