package talon.browser.desktop.commands
{
	import talon.browser.core.App;
	import talon.browser.core.utils.Command;

	public class ChangeSettingCommand extends Command
	{
		private var _name:String;
		private var _value:*;
		private var _alternate:*;

		public function ChangeSettingCommand(platform:App, name:String, value:*, alternate:* = null)
		{
			super(platform);
			platform.settings.addPropertyListener(name, dispatchEventChange);
			_name = name;
			_value = value;
			_alternate = alternate;
		}

		public override function execute():void
		{
			platform.settings.setValue(_name, (isActive && _alternate!==null) ? _alternate : _value);
		}

		public override function get isActive():Boolean
		{
			return platform.settings.getValue(_name) == _value;
		}
	}
}