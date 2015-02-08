package browser.commands
{
	import browser.utils.Constants;
	import browser.AppController;

	public class SettingCommand extends Command
	{
		private var _controller:AppController;
		private var _name:String;
		private var _value:*;
		private var _alternate:*;

		public function SettingCommand(controller:AppController, name:String, value:*, alternate:* = null)
		{
			_controller = controller;
			_controller.settings.addSettingListener(name, dispatchEvent);
			_name = name;
			_value = value;
			_alternate = alternate;
		}

		public override function execute():void
		{
			_controller.settings.setValue(_name, (isActive && _alternate!=null) ? _alternate : _value);
		}

		public override function get isActive():Boolean
		{
			return _controller.settings.getValueOrDefault(_name) == _value;
		}
	}
}