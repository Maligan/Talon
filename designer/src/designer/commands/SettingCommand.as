package designer.commands
{
	import designer.DesignerController;

	public class SettingCommand extends DesignerCommand
	{
		private var _controller:DesignerController;
		private var _name:String;
		private var _value:String;
		private var _alternate:String;

		public function SettingCommand(controller:DesignerController, name:String, value:String, alternate:String = null)
		{
			_controller = controller;
			_controller.settings.addSettingListener(name, dispatchEvent);
			_name = name;
			_value = value;
			_alternate = alternate;
		}

		public override function execute():void
		{
			_controller.settings.setValue(_name, (isActive && _alternate) ? _alternate : _value);
		}

		public override function get isActive():Boolean
		{
			return _controller.settings.getValueOrDefault(_name, DesignerConstants.SETTING_BACKGROUND_CHESS) == _value;
		}
	}
}