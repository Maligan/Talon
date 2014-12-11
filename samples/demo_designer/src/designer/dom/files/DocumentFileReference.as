package designer.dom.files
{
	import designer.dom.*;
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
			trace(_file.nativePath, e.type);
			dispatchEventWith(Event.CHANGE);
		}

		public function equals(link:DocumentFileReference):Boolean
		{
			return url == link.url;
		}

		public function read():ByteArray
		{
			if (removed) throw new ArgumentError("File was removed");

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
			if (extension == "xml") return DocumentFileType.PROTOTYPE;
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

		public function get url():String
		{
			return _file.url;
		}

		/** File is obsolete and must be removed from document. */
		public function get removed():Boolean
		{
			return !_file.exists;
		}

		/** @private For internal usage ONLY. */
		public function get file():File
		{
			return _file;
		}
	}
}