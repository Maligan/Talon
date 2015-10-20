package talon.browser.commands
{
	import talon.browser.AppPlatform;

	public class ChangeSettingCommand extends Command
	{
		private var _name:String;
		private var _value:*;
		private var _alternate:*;

		public function ChangeSettingCommand(controller:AppPlatform, name:String, value:*, alternate:* = null)
		{
			super(controller);
			controller.settings.addPropertyListener(name, dispatchEvent);
			_name = name;
			_value = value;
			_alternate = alternate;
		}

		public override function execute():void
		{
			controller.settings.setValue(_name, (isActive && _alternate!==null) ? _alternate : _value);
		}

		public override function get isActive():Boolean
		{
			return controller.settings.getValueOrDefault(_name) == _value;
		}
	}
}