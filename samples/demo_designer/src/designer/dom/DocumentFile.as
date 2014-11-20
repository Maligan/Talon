package designer.dom
{
	import com.adobe.air.filesystem.FileMonitor;
	import com.adobe.air.filesystem.events.FileMonitorEvent;
	import flash.events.Event;
	import flash.filesystem.File;
	import starling.events.EventDispatcher;

	[Event(name="change", type="starling.events.Event")]
	public class DocumentFile extends EventDispatcher
	{
		private var _type:String;
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

		public function equals(file:DocumentFile):Boolean
		{
			return path == file.path;
		}

		/** @see designer.dom.DocumentFileType */
		public function get type():String
		{
			return _type;
		}

		public function get path():String
		{
			return _file.nativePath;
		}
	}
}