package designer.dom
{
	public class DocumentTaskTracker
	{
		private var _taskCount:int = 0;
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
	}
}
