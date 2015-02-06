package browser.commands
{
	import browser.AppController;
	import browser.popups.ProfilePopup;
	import browser.utils.DeviceProfile;
	import browser.utils.DeviceProfile;

	import starling.events.Event;

	public class ProfileCommand extends Command
	{
		private var _controller:AppController;
		private var _profile:DeviceProfile;

		public function ProfileCommand(controller:AppController, profile:DeviceProfile)
		{
			_controller = controller;
			_controller.addEventListener(AppController.EVENT_PROFILE_CHANGE, onProfileChange);
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