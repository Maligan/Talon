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
			return path == file.path;
		}

		public function get data():ByteArray
		{
			var stream:FileStream = new FileStream();

			try
			{
				var result:ByteArray = new ByteArray();
				stream.open(_file, FileMode.READ);
				stream.readBytes(result, 0, stream.bytesAvailable);
				return result;
			}
			finally
			{
				stream.close();
			}

			return null;
		}

		/** @see designer.dom.DocumentFileType */
		public function get type():String
		{
			if (path.indexOf(".png") != -1) return DocumentFileType.IMAGE;
			if (path.indexOf(".xml") != -1) return DocumentFileType.PROTOTYPE;
			if (path.indexOf(".css") != -1) return DocumentFileType.STYLE;
			if (path.indexOf(".tdp") != -1) return DocumentFileType.PROJECT;
			return DocumentFileType.UNKNOWN;
		}

		public function get path():String
		{
			return _file.nativePath;
		}
	}
}