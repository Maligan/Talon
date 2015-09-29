package browser.ui
{
	import browser.*;
	import browser.commands.*;
	import browser.document.DocumentEvent;
	import browser.ui.popups.ProfilePopup;
	import browser.utils.DeviceProfile;
	import browser.utils.NativeMenuAdapter;

	import flash.display.NativeMenuItem;

	import flash.display.NativeWindow;
	import flash.filesystem.File;
	import flash.ui.Keyboard;

	import talon.enums.Orientation;

	public class AppUINativeMenu
	{
		private var _controller:AppController;
		private var _menu:NativeMenuAdapter;

		private var _prevTemplates:Vector.<String>;
		private var _prevDocuments:Array;

		public function AppUINativeMenu(controller:AppController)
		{
			_controller = controller;
			_menu = new NativeMenuAdapter();

			// File
			_menu.push("file",                                  AppConstants.T_MENU_FILE);
			_menu.push("file/new",                              AppConstants.T_MENU_FILE_NEW_DOCUMENT,                  new CreateDocumentCommand(_controller), "n");
//			_menu.push("file/instantiate",                      AppConstants.T_MENU_FILE_NEW_WINDOW,                    new CreateWindowCommand(),              "n", [Keyboard.CONTROL, Keyboard.SHIFT]);
			_menu.push("file/-");
			_menu.push("file/recent",                           AppConstants.T_MENU_FILE_RECENT);
			_menu.push("file/open",                             AppConstants.T_MENU_FILE_OPEN,                          new OpenDocumentCommand(_controller),   "o");
			_menu.push("file/-");
			_menu.push("file/closeDocument",                    AppConstants.T_MENU_FILE_CLOSE_DOCUMENT,                new CloseDocumentCommand(_controller),  "w");
			_menu.push("file/closeBrowser",                     AppConstants.T_MENU_FILE_CLOSE_BROWSER,                 new CloseWindowCommand(_controller),    "w", [Keyboard.CONTROL, Keyboard.SHIFT]);
			_menu.push("file/-");
			_menu.push("file/preference",                       AppConstants.T_MENU_FILE_PREFERENCES);
			_menu.push("file/preference/theme",                 AppConstants.T_MENU_FILE_PREFERENCES_BACKGROUND);
			_menu.push("file/preference/theme/dark",            AppConstants.T_MENU_FILE_PREFERENCES_BACKGROUND_DARK,   new ChangeSettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_DARK));
			_menu.push("file/preference/theme/light",           AppConstants.T_MENU_FILE_PREFERENCES_BACKGROUND_LIGHT,  new ChangeSettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_LIGHT));
			_menu.push("file/preference/stats",                 AppConstants.T_MENU_FILE_PREFERENCES_STATS,             new ChangeSettingCommand(_controller, AppConstants.SETTING_STATS, true, false));
			_menu.push("file/preference/resize",                AppConstants.T_MENU_FILE_PREFERENCES_LOCK_RESIZE,       new ChangeSettingCommand(_controller, AppConstants.SETTING_LOCK_RESIZE, true, false));
			_menu.push("file/preference/alwaysOnTop",           AppConstants.T_MENU_FILE_PREFERENCES_ALWAYS_ON_TOP,     new ChangeSettingCommand(_controller, AppConstants.SETTING_ALWAYS_ON_TOP, true, false));
			_menu.push("file/preference/autoReopen",            AppConstants.T_MENU_FILE_PREFERENCES_AUTO_REOPEN,       new ChangeSettingCommand(_controller, AppConstants.SETTING_AUTO_REOPEN, true, false));
			_menu.push("file/preference/autoUpdate",            AppConstants.T_MENU_FILE_PREFERENCES_AUTO_UPDATE,      new ChangeSettingCommand(_controller, AppConstants.SETTING_CHECK_FOR_UPDATE_ON_STARTUP, true, false));
			_menu.push("file/-");
			_menu.push("file/publish",                          AppConstants.T_MENU_FILE_PUBLISH_AS,                    new PublishCommand(_controller),        "s", [Keyboard.CONTROL, Keyboard.SHIFT]);

			// View
			_menu.push("view",                                  AppConstants.T_MENU_VIEW);
			_menu.push("view/zoomIn",                           AppConstants.T_MENU_VIEW_ZOOM_IN,                       new ChangeZoomCommand(_controller, +25),   "=");
			_menu.push("view/zoomOut",                          AppConstants.T_MENU_VIEW_ZOOM_OUT,                      new ChangeZoomCommand(_controller, -25),   "-");
			_menu.push("view/-");
			_menu.push("view/orientation",                      AppConstants.T_MENU_VIEW_ORIENTATION);
			_menu.push("view/orientation/portrait",             AppConstants.T_MENU_VIEW_ORIENTATION_PORTRAIT,          new ChangeOrientationCommand(_controller, Orientation.VERTICAL), "p", [Keyboard.ALTERNATE]);
			_menu.push("view/orientation/landscape",            AppConstants.T_MENU_VIEW_ORIENTATION_LANDSCAPE,         new ChangeOrientationCommand(_controller, Orientation.HORIZONTAL), "l", [Keyboard.ALTERNATE]);
			_menu.push("view/profile",                          AppConstants.T_MENU_VIEW_PROFILE);
			_menu.push("view/profile/custom",                   AppConstants.T_MENU_VIEW_PROFILE_CUSTOM,                new OpenPopupCommand(_controller, ProfilePopup, controller.profile), "0", [Keyboard.ALTERNATE]);
			_menu.push("view/profile/-");

			var profiles:Vector.<DeviceProfile> = DeviceProfile.getProfiles();
			for (var i:int = 0; i < profiles.length; i++)
			{
				var profileNumber:String = (i+1).toString();
				var profile:DeviceProfile = profiles[i];
				_menu.push("view/profile/" + profile.id, null, new ChangeProfileCommand(_controller, profile), profileNumber, [Keyboard.ALTERNATE]);
			}

			// Navigate
			_menu.push("navigate",                      AppConstants.T_MENU_NAVIGATE);
			_menu.push("navigate/openProjectFolder",    AppConstants.T_MENU_NAVIGATE_OPEN_DOCUMENT_FOLDER, new OpenDocumentFolderCommand(_controller));
			_menu.push("navigate/search",               AppConstants.T_MENU_NAVIGATE_SEARCH);

			_controller.documentDispatcher.addEventListener(DocumentEvent.CHANGED, refreshDocumentTemplatesList);
			_controller.addEventListener(AppController.EVENT_DOCUMENT_CHANGE, refreshDocumentTemplatesList);
			refreshDocumentTemplatesList();

			_controller.settings.addPropertyListener(AppConstants.SETTING_RECENT_DOCUMENTS, refreshRecentOpenedDocumentsList);
			refreshRecentOpenedDocumentsList();

			_menu.push("help",          AppConstants.T_MENU_HELP);
			_menu.push("help/online",   AppConstants.T_MENU_HELP_ONLINE);
			_menu.push("help/update",   AppConstants.T_MENU_HELP_UPDATE, new UpdateCommand(_controller));

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
					recentMenu.push(path, null, new OpenDocumentCommand(_controller, new File(path)));

				recentMenu.push("-");
				recentMenu.push("clear", AppConstants.T_MENU_FILE_RECENT_CLEAR, new ChangeSettingCommand(_controller, AppConstants.SETTING_RECENT_DOCUMENTS, []));
			}
		}

        private function isFileByPathExist(path:String, index:int, array:Array):Boolean
        {
            var file:File = new File(path);
            return file.exists;
        }

		private function refreshDocumentTemplatesList():void
		{
			var templates:Vector.<String> = _controller.document ? _controller.document.factory.templateIds: new <String>[];
			if (isEqual(templates, _prevTemplates)) return;
			_prevTemplates = templates;

			var submenu:NativeMenuAdapter = _menu.getChildByPath("navigate/search");
			submenu.removeChildren();
			submenu.isEnabled = templates.length != 0;
			submenu.isMenu = true;

			for each (var prototypeId:String in templates)
				submenu.push(prototypeId, null, new ChangeCurrentTemplateCommand(_controller, prototypeId));
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