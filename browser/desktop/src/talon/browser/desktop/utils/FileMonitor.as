package talon.browser.desktop.utils
{
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.Timer;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	/** Dispatched when file.modificationDate / file.exists changed. */
	[Event(name="change", type="starling.events.Event")]
	
	/** Class that monitors files for changes. */
	public class FileMonitor extends EventDispatcher
	{
		private static const sTimers:Object = {};

		private static function getTimerFromPool(interval:int):Timer
		{
			interval = Math.max(interval, 1000);

			var timer:Timer = sTimers[interval];
			if (timer == null)
				timer = sTimers[interval] = new Timer(interval);

			return timer;

		}

		private var _timer:Timer;
		private var _watching:Boolean;
		private var _file:File;
		private var _timestamp:Number;
		
		/**
		 * 	@parameter file The File that will be monitored for changes.
		 * 
		 * 	@param interval How often in milliseconds the file is polled for
		 * 	change events. Default value is 1000, minimum value is 1000
		 */ 
		public function FileMonitor(file:File = null, interval:int = -1)
		{
			this.file = file;
			this.interval = interval;
		}

		/** How often the system is polled for Volume change events. */
		public function get interval():int{ return _timer.delay; }
		public function set interval(value:int):void
		{
			_timer && _timer.removeEventListener(TimerEvent.TIMER, onTimerEvent);
			_timer = getTimerFromPool(value);
			_timer.addEventListener(TimerEvent.TIMER, onTimerEvent);
			_timer.running || _timer.start();
		}

		/** File being monitored for changes. */
		public function get file():File { return _file; }
		public function set file(file:File):void
		{
			_file = file;

			try { _timestamp = _file.modificationDate.getTime() }
			catch (e:Error) { _timestamp = NaN }
		}

		/** Begins monitoring the specified file for changes. */
		public function watch():void
		{
			_watching = true;
		}

		/** Stops watching the specified file for changes. */
		public function unwatch():void
		{
			_watching = false;
		}
		
		private function onTimerEvent(e:TimerEvent):void
		{
			if (_watching && _file)
			{
				try
				{
					var timestamp:Number = _file.modificationDate.getTime();
					if (timestamp != _timestamp)
					{
						_timestamp = timestamp;
						dispatchEventWith(Event.CHANGE);
					}
				}
				catch (e:Error)
				{
					if (_timestamp == _timestamp)
					{
						_timestamp = NaN;
						dispatchEventWith(Event.CHANGE);
					}
				}
			}
		}
	}
}