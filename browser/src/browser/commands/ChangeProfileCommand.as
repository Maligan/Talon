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
			controller.profile.addEventListener(Event.CHANGE, onProfileChange);
			_profile = profile;
		}

		private function onProfileChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			controller.profile.copyFrom(_profile);
		}

		public override function get isActive():Boolean
		{
			return controller.profile.equals(_profile);
		}
	}
}