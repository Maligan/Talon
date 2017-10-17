package talon.browser.desktop.utils
{
	import flash.filesystem.File;

	import starling.events.Event;

	import talon.browser.core.utils.Storage;
	import talon.utils.ParseUtil;

	public class DesktopStorage extends Storage
	{
		private var _monitor:FileMonitor;
		
		public function DesktopStorage(file:File)
		{
			_monitor = new FileMonitor();
			_monitor.addEventListener(Event.CHANGE, sync);
			_monitor.file = file;
			_monitor.watch();

			sync();
		}
		
		private function sync():void
		{
			if (_monitor.file.exists)
			{
				var fileText:String = FileUtil.readText(_monitor.file);
				var props:Object = ParseUtil.parseProperties(fileText);
				
				for (var key:String in props)
					setValue(key, props[key]);
			}
			
			dispatchEventWith(Event.UPDATE);
		}

		public override function dispose():void
		{
			_monitor.file = null;
			_monitor.unwatch();
		}
	}
}
