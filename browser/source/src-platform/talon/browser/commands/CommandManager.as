package talon.browser.commands
{
	public class CommandManager
	{
		private var _history:Vector.<Command>;

		public function CommandManager()
		{
			_history = new Vector.<Command>();
		}

		//
		// Command history
		// Any command can add self to this history
		// And after this another code
		//
		public function push(command:Command):void { _history.push(command); }
		public function clear():void { _history.length = 0; }
		public function pop():Command { return _history.pop(); }
	}
}