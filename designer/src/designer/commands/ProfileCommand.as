package designer.commands
{
	import designer.DesignerController;
	import designer.popups.ProfilePopup;
	import designer.utils.DeviceProfile;
	import designer.utils.DeviceProfile;

	import starling.events.Event;

	public class ProfileCommand extends DesignerCommand
	{
		private var _controller:DesignerController;
		private var _profile:DeviceProfile;

		public function ProfileCommand(controller:DesignerController, profile:DeviceProfile)
		{
			_controller = controller;
			_controller.addEventListener(DesignerController.EVENT_PROFILE_CHANGE, onProfileChange);
			_profile = profile;
		}

		private function onProfileChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			if (_profile == DeviceProfile.CUSTOM)
			{
				var popup:ProfilePopup = new ProfilePopup();
				popup.open();
			}
			else
			{
				_controller.profile = _profile;
			}
		}

		public override function get isActive():Boolean
		{
			return _profile != DeviceProfile.CUSTOM && _controller.profile == _profile;
		}
	}
}