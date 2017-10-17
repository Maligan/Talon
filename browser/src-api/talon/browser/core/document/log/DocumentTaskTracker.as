package talon.browser.core.document.log
{
	import flash.utils.Dictionary;

	public class DocumentTaskTracker
	{
		private var _taskCount:int;
		private var _taskKeys:Dictionary;
		private var _complete:Function;

		public function DocumentTaskTracker(complete:Function)
		{
			_complete = complete;
			_taskCount = 0;
			_taskKeys = new Dictionary();
		}

		public function begin(key:* = null):void
		{
			_taskCount++;
			if (key) _taskKeys[key] = int(_taskKeys[key]) + 1;
		}

		public function end(key:* = null):void
		{
			_taskCount--;
			if (key) _taskKeys[key] = int(_taskKeys[key]) - 1;
			if (_taskKeys[key] === 0) delete _taskKeys[key];

			_taskCount == 0 && _complete();
		}

		public function get isBusy():Boolean
		{
			return _taskCount != 0;
		}
	}
}
