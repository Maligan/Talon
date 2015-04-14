package browser.dom.log
{
	public class DocumentTaskTracker
	{
		public var _taskCount:int = 0;
		private var _complete:Function;

		public function DocumentTaskTracker(complete:Function)
		{
			_complete = complete;
		}

		public function begin():void
		{
			_taskCount++;
		}

		public function end():void
		{
			_taskCount--;
			_taskCount == 0 && _complete();
		}

		public function get isBusy():Boolean
		{
			return _taskCount != 0;
		}
	}
}
