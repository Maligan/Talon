package browser.dom
{
	public class DocumentTaskTracker
	{
		public var _taskCount:int = 0;
		private var _complete:Function;

		public function DocumentTaskTracker(complete:Function)
		{
			_complete = complete;
		}

		public function begin(msg:String = null):void
		{
//			msg && trace(msg);
			_taskCount++;
		}

		public function end(msg:String = null):void
		{
//			msg && trace(msg);
			_taskCount--;
			_taskCount == 0 && _complete();
		}

		internal function get isBusy():Boolean
		{
			return _taskCount != 0;
		}
	}
}
