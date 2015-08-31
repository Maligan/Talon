package browser.commands
{
	import browser.AppController;
	import browser.ui.popups.ProfilePopup;
	import browser.utils.DeviceProfile;
	import browser.utils.DeviceProfile;

	import starling.events.Event;

	public class ChangeProfileCommand extends Command
	{
		private var _profile:DeviceProfile;

		public function ChangeProfileCommand(controller:AppController, profile:DeviceProfile)
		{
			super(controller);
			controller.addEventListener(AppController.EVENT_PROFILE_CHANGE, onProfileChange);
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
//				popup.open();
			}
			else
			{
				controller.profile = _profile;
			}
		}

		public override function get isActive():Boolean
		{
			return _profile != DeviceProfile.CUSTOM && controller.profile == _profile;
		}
	}
}