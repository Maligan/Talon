package browser
{
	import browser.commands.*;
	import browser.dom.DocumentEvent;
	import browser.utils.DeviceProfile;
	import browser.utils.NativeMenuAdapter;

	import flash.display.NativeWindow;
	import flash.filesystem.File;
	import flash.ui.Keyboard;

	import talon.enums.Orientation;

	public class AppUINativeMenu
	{
		private var _controller:AppController;
		private var _menu:NativeMenuAdapter;

		public function AppUINativeMenu(controller:AppController)
		{
			_controller = controller;
			_menu = new NativeMenuAdapter();

			// File
			_menu.push("file",                  AppConstants.T_MENU_FILE);
			_menu.push("file/new",              AppConstants.T_MENU_FILE_NEW_DOCUMENT,      new NewDocumentCommand(_controller),    "n");
			_menu.push("file/-");
			_menu.push("file/open",             AppConstants.T_MENU_FILE_OPEN,              new OpenDocumentCommand(_controller),   "o");
			_menu.push("file/recent",           AppConstants.T_MENU_FILE_RECENT);
			_menu.push("file/-");
			_menu.push("file/closeDocument",    AppConstants.T_MENU_FILE_CLOSE_DOCUMENT,    new CloseDocumentCommand(_controller),  "w");
			_menu.push("file/closeBrowser",     AppConstants.T_MENU_FILE_CLOSE_BROWSER,     new CloseBrowserCommand(_controller),   "w", [Keyboard.CONTROL, Keyboard.SHIFT]);
			_menu.push("file/-");
			_menu.push("file/publish",          AppConstants.T_MENU_FILE_PUBLISH_AS,        new PublishCommand(_controller),        "s", [Keyboard.CONTROL, Keyboard.SHIFT]);

			// View
			_menu.push("view",                                  AppConstants.T_MENU_VIEW);
			_menu.push("view/preference",                       AppConstants.T_MENU_VIEW_PREFERENCES);
			_menu.push("view/preference/theme",                 AppConstants.T_MENU_VIEW_PREFERENCES_BACKGROUND);
			_menu.push("view/preference/theme/transparent",     AppConstants.T_MENU_VIEW_PREFERENCES_BACKGROUND_CHESS,  new SettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_CHESS));
			_menu.push("view/preference/theme/dark",            AppConstants.T_MENU_VIEW_PREFERENCES_BACKGROUND_DARK,   new SettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_DARK));
			_menu.push("view/preference/theme/light",           AppConstants.T_MENU_VIEW_PREFERENCES_BACKGROUND_LIGHT,  new SettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_LIGHT));
			_menu.push("view/preference/stats",                 AppConstants.T_MENU_VIEW_PREFERENCES_STATS,             new SettingCommand(_controller, AppConstants.SETTING_STATS, true, false));
			_menu.push("view/preference/resize",                AppConstants.T_MENU_VIEW_PREFERENCES_LOCK_RESIZE,       new SettingCommand(_controller, AppConstants.SETTING_LOCK_RESIZE, true, false));
			_menu.push("view/preference/alwaysOnTop",           AppConstants.T_MENU_VIEW_PREFERENCES_ALWAYS_ON_TOP,     new SettingCommand(_controller, AppConstants.SETTING_ALWAYS_ON_TOP, true, false));
			_menu.push("view/preference/autoReopen",            AppConstants.T_MENU_VIEW_PREFERENCES_AUTO_REOPEN,       new SettingCommand(_controller, AppConstants.SETTING_AUTO_REOPEN, true, false));
			_menu.push("view/-");
			_menu.push("view/zoomIn",                           AppConstants.T_MENU_VIEW_ZOOM_IN,                       new ZoomCommand(_controller, +25),   "=");
			_menu.push("view/zoomOut",                          AppConstants.T_MENU_VIEW_ZOOM_OUT,                      new ZoomCommand(_controller, -25),   "-");
			_menu.push("view/-");
			_menu.push("view/orientation",                      AppConstants.T_MENU_VIEW_ORIENTATION);
			_menu.push("view/orientation/portrait",             AppConstants.T_MENU_VIEW_ORIENTATION_PORTRAIT,          new OrientationCommand(_controller, Orientation.VERTICAL), "p", [Keyboard.CONTROL, Keyboard.SHIFT]);
			_menu.push("view/orientation/landscape",            AppConstants.T_MENU_VIEW_ORIENTATION_LANDSCAPE,         new OrientationCommand(_controller, Orientation.HORIZONTAL), "l", [Keyboard.CONTROL, Keyboard.SHIFT]);
			_menu.push("view/profile",                          AppConstants.T_MENU_VIEW_PROFILE);
			_menu.push("view/profile/custom",                   AppConstants.T_MENU_VIEW_PROFILE_CUSTOM,                new ProfileCommand(_controller, DeviceProfile.CUSTOM));
			_menu.push("view/profile/-");

			var profiles:Vector.<DeviceProfile> = DeviceProfile.getProfiles();
			for (var i:int = 0; i < profiles.length; i++)
			{
				var profileNumber:String = (i+1).toString();
				var profile:DeviceProfile = profiles[i];
				_menu.push("view/profile/" + profile.id, null, new ProfileCommand(_controller, profile), profileNumber, [Keyboard.ALTERNATE]);
			}

			// Navigate
			_menu.push("navigate",                      AppConstants.T_MENU_NAVIGATE);
			_menu.push("navigate/openProjectFolder",    AppConstants.T_MENU_NAVIGATE_OPEN_DOCUMENT_FOLDER, new OpenDocumentFolderCommand(_controller));
			_menu.push("navigate/search",               AppConstants.T_MENU_NAVIGATE_SEARCH);

			_controller.documentDispatcher.addEventListener(DocumentEvent.CHANGED, refreshDocumentTemplatesList);
			_controller.addEventListener(AppController.EVENT_DOCUMENT_CHANGE, refreshDocumentTemplatesList);
			refreshDocumentTemplatesList();

			_controller.settings.addPropertyListener(AppConstants.SETTING_RECENT_ARRAY, refreshRecentOpenedDocumentsList);
			refreshRecentOpenedDocumentsList();

			_menu.push("help",          AppConstants.T_MENU_HELP);
			_menu.push("help/online",   AppConstants.T_MENU_HELP_ONLINE);
			_menu.push("help/update",   AppConstants.T_MENU_HELP_UPDATE, new UpdateCommand(_controller));
			_menu.push("help/about",    AppConstants.T_MENU_HELP_ABOUT);

			if (NativeWindow.supportsMenu) controller.root.stage.nativeWindow.menu = _menu.nativeMenu;
		}

		private function refreshRecentOpenedDocumentsList():void
		{
			var recent:Array = _controller.settings.getValueOrDefault(AppConstants.SETTING_RECENT_ARRAY, []);
			var recentMenu:NativeMenuAdapter = _menu.getChildByPath("file/recent");
			recentMenu.isMenu = true;
			recentMenu.removeChildren();
			recentMenu.isEnabled = recent.length > 0;

			if (recent.length > 0)
			{
				for each (var path:String in recent)
					recentMenu.push(path, null, new OpenDocumentCommand(_controller, new File(path)));

				recentMenu.push("-");
				recentMenu.push("clear", AppConstants.T_MENU_FILE_RECENT_CLEAR, new SettingCommand(_controller, AppConstants.SETTING_RECENT_ARRAY, []));
			}
		}

		private function refreshDocumentTemplatesList():void
		{
			var templates:Vector.<String> = _controller.document ? _controller.document.factory.templateIds: new <String>[];

			var submenu:NativeMenuAdapter = _menu.getChildByPath("navigate/search");
			submenu.removeChildren();
			submenu.isEnabled = templates.length != 0;
			submenu.isMenu = true;

			for each (var prototypeId:String in templates)
				submenu.push(prototypeId, null, new SelectCommand(_controller, prototypeId));
		}
	}
}