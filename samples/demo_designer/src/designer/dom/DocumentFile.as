package designer.dom
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
	public class DocumentFile extends EventDispatcher
	{
		private var _file:File;
		private var _monitor:FileMonitor;

		public function DocumentFile(file:File)
		{
			if (!file) throw new ArgumentError("File must be non null");
			if (!file.exists) throw new ArgumentError("File must be exists");

			_file = file;
			_monitor = new FileMonitor(_file);
			_monitor.addEventListener(FileMonitorEvent.CHANGE, onFileChange);
			_monitor.addEventListener(FileMonitorEvent.MOVE, onFileMove);
			_monitor.watch();
		}

		private function onFileChange(e:FileMonitorEvent):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		private function onFileMove(e:FileMonitorEvent):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public function resolve(path:String):String
		{
			return _file.parent.resolvePath(path).nativePath;
		}

		public function equals(file:DocumentFile):Boolean
		{
			return url == file.url;
		}

		public function get data():ByteArray
		{
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

		/** @see designer.dom.DocumentFileType */
		public function get type():String
		{
			if (url.indexOf(DesignerConstants.DESIGNER_FILE_EXTENSION) != -1) return DocumentFileType.PROJECT;
			if (url.indexOf(".xml") != -1) return DocumentFileType.PROTOTYPE;
			if (url.indexOf(".png") != -1) return DocumentFileType.IMAGE;
			if (url.indexOf(".css") != -1) return DocumentFileType.STYLE;
			return DocumentFileType.UNKNOWN;
		}

		public function get url():String
		{
			return _file.url;
		}

		/** For internal usage ONLY. */
		internal function get file():File
		{
			return _file;
		}
	}
}