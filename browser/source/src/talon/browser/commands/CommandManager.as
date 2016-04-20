package talon.browser.commands
{
	public class CommandManager
	{
		private var _history:Vector.<Command>;
		private var _historyCursor:int;

		public function CommandManager()
		{
			_history = new Vector.<Command>();
		}

		public function register(key:String, command:Command):void
		{

		}

		public function execute(key:String):void
		{

		}

		//
		// Command history
		// Any command can add self to this history
		//
		public function push(command:Command):void { _historyCursor = _history.push(command); }
		public function clear():void { _history.length = _historyCursor = 0; }
		public function undo():void { if (_historyCursor > 0) _history[--_historyCursor].rollback(); }
		public function redo():void { if (_historyCursor < _history.length) _history[_historyCursor++].execute(); }
	}
}