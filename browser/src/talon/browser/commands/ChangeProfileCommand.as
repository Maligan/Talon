package talon.browser.commands
{
	import talon.browser.AppController;
	import talon.browser.popups.ProfilePopup;
	import talon.browser.utils.DeviceProfile;
	import talon.browser.utils.DeviceProfile;

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