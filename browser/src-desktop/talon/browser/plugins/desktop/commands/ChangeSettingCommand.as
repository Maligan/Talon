package talon.browser.plugins.desktop.commands
{
	import talon.browser.commands.*;
	import talon.browser.AppPlatform;

	public class ChangeSettingCommand extends Command
	{
		private var _name:String;
		private var _value:*;
		private var _alternate:*;

		public function ChangeSettingCommand(platform:AppPlatform, name:String, value:*, alternate:* = null)
		{
			super(platform);
			platform.settings.addPropertyListener(name, dispatchEvent);
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
			return platform.settings.getValueOrDefault(_name) == _value;
		}
	}
}