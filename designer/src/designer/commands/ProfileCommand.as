package designer.commands
{
	import designer.DesignerController;
	import designer.utils.DeviceProfile;

	import starling.events.Event;

	public class ProfileCommand extends DesignerCommand
	{
		private var _controller:DesignerController;
		private var _profile:DeviceProfile;

		public function ProfileCommand(controller:DesignerController, profile:DeviceProfile)
		{
			_controller = controller;
			_profile = profile;
		}

		public override function execute():void
		{
			_controller.profile = _profile;
			dispatchEventWith(Event.CHANGE);
		}

		public override function get isActive():Boolean
		{
			return _controller.profile == _profile;
		}
	}
}