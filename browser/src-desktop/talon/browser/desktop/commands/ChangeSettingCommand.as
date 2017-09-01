package talon.browser.desktop.commands
{
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.utils.Command;

	public class ChangeSettingCommand extends Command
	{
		private var _name:String;
		private var _value:*;
		private var _alternate:*;

		public function ChangeSettingCommand(platform:AppPlatform, name:String, value:*, alternate:* = null)
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