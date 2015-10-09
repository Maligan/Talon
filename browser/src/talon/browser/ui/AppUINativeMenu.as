package talon.browser.ui
{
	import talon.browser.*;
	import talon.browser.commands.*;
	import talon.browser.document.DocumentEvent;
	import talon.browser.ui.popups.GoToPopup;
	import talon.browser.ui.popups.ProfilePopup;
	import talon.browser.utils.DeviceProfile;
	import talon.browser.utils.NativeMenuAdapter;

	import flash.display.NativeMenuItem;

	import flash.display.NativeWindow;
	import flash.events.KeyboardEvent;
	import flash.filesystem.File;
	import flash.ui.Keyboard;

	import talon.enums.Orientation;

	public class AppUINativeMenu
	{
		private var _controller:AppController;
		private var _menu:NativeMenuAdapter;
		private var _prevDocuments:Array;

		public function AppUINativeMenu(controller:AppController)
		{
			_controller = controller;
			_menu = new NativeMenuAdapter();

			// File
			_menu.insert("file",                                  AppConstants.T_MENU_FILE);
			_menu.insert("file/new",                              AppConstants.T_MENU_FILE_NEW_DOCUMENT,                  new CreateDocumentCommand(_controller), "n");
//			_menu.push("file/instantiate",                      AppConstants.T_MENU_FILE_NEW_WINDOW,                    new CreateWindowCommand(),              "n", [Keyboard.CONTROL, Keyboard.SHIFT]);
			_menu.insert("file/-");
			_menu.insert("file/recent",                           AppConstants.T_MENU_FILE_RECENT);
			_menu.insert("file/open",                             AppConstants.T_MENU_FILE_OPEN,                          new OpenDocumentCommand(_controller),   "o");
			_menu.insert("file/-");
			_menu.insert("file/closeDocument",                    AppConstants.T_MENU_FILE_CLOSE_DOCUMENT,                new CloseDocumentCommand(_controller),  "w");
			_menu.insert("file/closeBrowser",                     AppConstants.T_MENU_FILE_CLOSE_BROWSER,                 new CloseWindowCommand(_controller),    "w", [Keyboard.CONTROL, Keyboard.SHIFT]);
			_menu.insert("file/-");
			_menu.insert("file/preference",                       AppConstants.T_MENU_FILE_PREFERENCES);
			_menu.insert("file/preference/stats",                 AppConstants.T_MENU_FILE_PREFERENCES_STATS,             new ChangeSettingCommand(_controller, AppConstants.SETTING_STATS, true, false));
			_menu.insert("file/preference/resize",                AppConstants.T_MENU_FILE_PREFERENCES_LOCK_RESIZE,       new ChangeSettingCommand(_controller, AppConstants.SETTING_LOCK_RESIZE, true, false));
			_menu.insert("file/preference/alwaysOnTop",           AppConstants.T_MENU_FILE_PREFERENCES_ALWAYS_ON_TOP,     new ChangeSettingCommand(_controller, AppConstants.SETTING_ALWAYS_ON_TOP, true, false));
			_menu.insert("file/preference/autoReopen",            AppConstants.T_MENU_FILE_PREFERENCES_AUTO_REOPEN,       new ChangeSettingCommand(_controller, AppConstants.SETTING_AUTO_REOPEN, true, false));
			_menu.insert("file/preference/autoUpdate",            AppConstants.T_MENU_FILE_PREFERENCES_AUTO_UPDATE,       new ChangeSettingCommand(_controller, AppConstants.SETTING_CHECK_FOR_UPDATE_ON_STARTUP, true, false));
			_menu.insert("file/-");
			_menu.insert("file/publish",                          AppConstants.T_MENU_FILE_PUBLISH_AS,                    new PublishCommand(_controller),        "s", [Keyboard.CONTROL, Keyboard.SHIFT]);

			// View
			_menu.insert("view",                                  AppConstants.T_MENU_VIEW);
			_menu.insert("view/zoomIn",                           AppConstants.T_MENU_VIEW_ZOOM_IN,                       new ChangeZoomCommand(_controller, +25),   "=");
			_menu.insert("view/zoomOut",                          AppConstants.T_MENU_VIEW_ZOOM_OUT,                      new ChangeZoomCommand(_controller, -25),   "-");
			_menu.insert("view/-");
			_menu.insert("view/rotate",                           AppConstants.T_MENU_VIEW_ROTATE,                        new RotateCommand(_controller), "r", [Keyboard.CONTROL]);
			_menu.insert("view/theme",                            AppConstants.T_MENU_VIEW_BACKGROUND);
			_menu.insert("view/theme/dark",                       AppConstants.T_MENU_VIEW_BACKGROUND_DARK,               new ChangeSettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_DARK));
			_menu.insert("view/theme/light",                      AppConstants.T_MENU_VIEW_BACKGROUND_LIGHT,              new ChangeSettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_LIGHT));
			_menu.insert("view/profile",                          AppConstants.T_MENU_VIEW_PROFILE);
			_menu.insert("view/profile/custom",                   AppConstants.T_MENU_VIEW_PROFILE_CUSTOM,                new OpenPopupCommand(_controller, ProfilePopup, controller.profile), "0", [Keyboard.CONTROL]);
			_menu.insert("view/-");
			_menu.insert("view/fullscreen",                       AppConstants.T_MENU_VIEW_FULL_SCREEN,                   new ToggleFullScreenCommand(_controller), "f");
			_menu.insert("view/profile/-");

			var profiles:Vector.<DeviceProfile> = DeviceProfile.getProfiles();
			for (var i:int = 0; i < profiles.length; i++)
			{
				var profileNumber:String = (i+1).toString();
				var profile:DeviceProfile = profiles[i];
				_menu.insert("view/profile/" + profile.id, null, new ChangeProfileCommand(_controller, profile), profileNumber, [Keyboard.ALTERNATE]);
			}

			// Navigate
			_menu.insert("navigate",                      AppConstants.T_MENU_NAVIGATE);
			_menu.insert("navigate/openProjectFolder",    AppConstants.T_MENU_NAVIGATE_OPEN_DOCUMENT_FOLDER,              new OpenDocumentFolderCommand(_controller));
			_menu.insert("navigate/searchPopup",          AppConstants.T_MENU_NAVIGATE_SEARCH,                            new OpenGoToPopupCommand(_controller), "p", [Keyboard.CONTROL]);

			_controller.settings.addPropertyListener(AppConstants.SETTING_RECENT_DOCUMENTS, refreshRecentOpenedDocumentsList);
			refreshRecentOpenedDocumentsList();

			_menu.insert("help",          AppConstants.T_MENU_HELP);
			_menu.insert("help/online",   AppConstants.T_MENU_HELP_ONLINE);
			_menu.insert("help/update",   AppConstants.T_MENU_HELP_UPDATE, new UpdateCommand(_controller));

			if (NativeWindow.supportsMenu) controller.root.stage.nativeWindow.menu = _menu.nativeMenu;
		}

		private function refreshRecentOpenedDocumentsList():void
		{
			var recent:Array = _controller.settings.getValueOrDefault(AppConstants.SETTING_RECENT_DOCUMENTS, Array, []).filter(isFileByPathExist);
			if (isEqual(recent, _prevDocuments)) return;
			_prevDocuments = recent;

			var recentMenu:NativeMenuAdapter = _menu.getChildByPath("file/recent");
			recentMenu.isMenu = true;
			recentMenu.removeChildren();
			recentMenu.isEnabled = recent.length > 0;

			if (recent.length > 0)
			{
				for each (var path:String in recent)
					recentMenu.insert(path, null, new OpenDocumentCommand(_controller, new File(path)));

				recentMenu.insert("-");
				recentMenu.insert("clear", AppConstants.T_MENU_FILE_RECENT_CLEAR, new ChangeSettingCommand(_controller, AppConstants.SETTING_RECENT_DOCUMENTS, []));
			}
		}

        private function isFileByPathExist(path:String, index:int, array:Array):Boolean
        {
            var file:File = new File(path);
            return file.exists;
        }

		private static function isEqual(list1:*, list2:*):Boolean
		{
			if (list1 == null || list2 == null) return false;

			var length1:int = list1.length;
			var length2:int = list2.length;
			if (length1 != length2) return false;

			for (var i:int = 0; i < length1; i++)
				if (list1[i] != list2[i]) return false;

			return true;
		}

		public function get locked():Boolean { return _menu.isEnabled; }
		public function set locked(value:Boolean):void
		{
			if (_menu.isEnabled != value)
			{
				_menu.isEnabled = value;

				for each (var item:NativeMenuItem in _menu.nativeMenu.items)
					item.enabled = value;
			}
		}
	}
}