package browser
{
	import flash.desktop.NativeApplication;

	public class AppConstants
	{
		//
		// Application info
		//
		public static const APP_NAME:String = "Talon Browser";
		public static const APP_UPDATE_URL:String = "https://raw.githubusercontent.com/Maligan/Talon/master/browser/bin/update.xml";
		public static function get APP_VERSION():String
		{
			var xml:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = xml.namespace();
			var version:String = xml.ns::versionNumber;
			return version;
		}

		public static const BROWSER_DOCUMENT_EXTENSION:String = "talon";
		public static const BROWSER_PUBLISH_EXTENSION:String = "zip";
		public static const BROWSER_SUPPORTED_IMAGE_EXTENSIONS:Vector.<String> = new <String>["atf", "png", "jpg", "gif"];

		public static const ZOOM_MIN:int = 25;
		public static const ZOOM_MAX:int = 300;
		public static const HISTORY_RECENT_MAX:int = 10;

		public static const PROPERTY_SOURCE_PATH:String     = "source.path";
		public static const PROPERTY_SOURCE_IGNORE:String   = "source.ignore";
		public static const PROPERTY_EXPORT_PATH:String     = "export.path";
		public static const PROPERTY_EXPORT_IGNORE:String   = "export.ignore";
		public static const PROPERTY_EXPORT_EXEC:String     = "export.exec";

		public static const SETTING_BACKGROUND:String = "background";
		public static const SETTING_BACKGROUND_DARK:String = "dark";
		public static const SETTING_BACKGROUND_LIGHT:String = "light";
		public static const SETTING_BACKGROUND_DEFAULT:String = SETTING_BACKGROUND_DARK;
		public static const SETTING_BACKGROUND_STAGE_COLOR:Object = { "dark": 0x3F4142, "light": 0xBFBFBF };
		public static const SETTING_STATS:String = "stats";
		public static const SETTING_ZOOM:String = "zoom";
		public static const SETTING_LOCK_RESIZE:String = "lockWindowResize";
		public static const SETTING_ALWAYS_ON_TOP:String = "alwaysOnTop";
		public static const SETTING_AUTO_REOPEN:String = "autoReopen";
		public static const SETTING_RECENT_DOCUMENTS:String = "recentDocuments";
		public static const SETTING_RECENT_TEMPLATE:String = "recentTemplate";
		public static const SETTING_PROFILE:String = "profile";
		public static const SETTING_CHECK_FOR_UPDATE_ON_STARTUP:String = "checkForUpdateOnStartup";
		public static const SETTING_WINDOW_POSITION:String = "windowPosition";

		//
		// Language
		//
		public static const T_EXPORT_TITLE:String                           = "Export";
		public static const T_PROJECT_ROOT_TITLE:String                     = "Select Document root directory";
		public static const T_PROJECT_FILE_TITLE:String                     = "Select Document file";
		public static const T_PROJECT_FILE_DEFAULT_NAME:String              = "Untitled";
		public static const T_BROWSER_FILE_EXTENSION_NAME:String            = "Talon Designer Document";
		public static const T_BROWSER_EXPORT_FILE_EXTENSION_NAME:String     = "Zip Archive";
		public static const T_MENU_FILE:String                              = "File";
		public static const T_MENU_FILE_OPEN:String                         = "Open...";
		public static const T_MENU_FILE_NEW_DOCUMENT:String                 = "New Document...";
		public static const T_MENU_FILE_NEW_WINDOW:String                   = "New Window";
		public static const T_MENU_FILE_RECENT:String                       = "Open Recent";
		public static const T_MENU_FILE_RECENT_CLEAR:String                 = "Clear";
		public static const T_MENU_FILE_PUBLISH_AS:String                   = "Publish As...";
		public static const T_MENU_FILE_CLOSE_DOCUMENT:String               = "Close Document";
		public static const T_MENU_FILE_CLOSE_BROWSER:String                = "Close Window";
		public static const T_MENU_NAVIGATE:String                          = "Navigate";
		public static const T_MENU_NAVIGATE_OPEN_DOCUMENT_FOLDER:String     = "Go to Document Folder";
		public static const T_MENU_NAVIGATE_SEARCH:String                   = "Go to Template";
		public static const T_MENU_VIEW:String                              = "View";
		public static const T_MENU_FILE_PREFERENCES:String                  = "Preferences";
		public static const T_MENU_FILE_PREFERENCES_BACKGROUND:String       = "Background";
		public static const T_MENU_FILE_PREFERENCES_BACKGROUND_LIGHT:String = "Light";
		public static const T_MENU_FILE_PREFERENCES_BACKGROUND_DARK:String  = "Dark";
		public static const T_MENU_FILE_PREFERENCES_BACKGROUND_CHESS:String = "Transparent";
		public static const T_MENU_FILE_PREFERENCES_STATS:String            = "Show Stats";
		public static const T_MENU_FILE_PREFERENCES_LOCK_RESIZE:String      = "Lock Window Size";
		public static const T_MENU_FILE_PREFERENCES_ALWAYS_ON_TOP:String    = "Always On Top";
		public static const T_MENU_FILE_PREFERENCES_AUTO_REOPEN:String      = "Open Last Document on Startup";
		public static const T_MENU_FILE_PREFERENCES_AUTO_UPDATE:String      = "Check for Update on Startup";
		public static const T_MENU_VIEW_ZOOM_IN:String                      = "Zoom In";
		public static const T_MENU_VIEW_ZOOM_OUT:String                     = "Zoom Out";
		public static const T_MENU_VIEW_ORIENTATION:String                  = "Orientation";
		public static const T_MENU_VIEW_ORIENTATION_PORTRAIT:String         = "Portrait";
		public static const T_MENU_VIEW_ORIENTATION_LANDSCAPE:String        = "Landscape";
		public static const T_MENU_VIEW_PROFILE:String                      = "Profile";
		public static const T_MENU_VIEW_PROFILE_CUSTOM:String               = "Custom...";
		public static const T_MENU_VIEW_CONSOLE:String                      = "Console";
		public static const T_MENU_HELP:String                              = "Help";
		public static const T_MENU_HELP_ONLINE:String                       = "Online Documentation";
		public static const T_MENU_HELP_UPDATE:String                       = "Check for Update...";
	}
}
