package talon.browser.desktop.commands
{
	import talon.browser.core.AppConstants;
	import talon.browser.core.App;
	import talon.browser.core.utils.Command;

	public class ChangeProfileModeCommand extends Command
	{
		public function ChangeProfileModeCommand(platform:App)
		{
			super(platform);
			
			platform.settings.addPropertyListener(AppConstants.SETTING_SHOW_INSPECTOR, dispatchEventChange);
			platform.settings.addPropertyListener(AppConstants.SETTING_PROFILE_BIND_MODE, dispatchEventChange);
		}
		
		public override function get isExecutable():Boolean
		{
			return !platform.settings.getValue(AppConstants.SETTING_SHOW_INSPECTOR, Boolean, false);
		}
		
		public override function get isActive():Boolean
		{
			return isProfileBindModeEnable;
		}

		public override function execute():void
		{
			isProfileBindModeEnable = !isProfileBindModeEnable;
		}

		// Shortcuts
		public function get isProfileBindModeEnable():Boolean { return platform.settings.getValue(AppConstants.SETTING_PROFILE_BIND_MODE, Boolean, true) }
		public function set isProfileBindModeEnable(value:Boolean):void { platform.settings.setValue(AppConstants.SETTING_PROFILE_BIND_MODE, value) }
	}
}
