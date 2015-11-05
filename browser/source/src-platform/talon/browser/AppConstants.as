package talon.browser
{
	import flash.desktop.NativeApplication;

	public class AppConstants
	{
		//
		// Application info
		//
		public static const APP_NAME:String = "Talon Browser";
		public static const APP_UPDATE_URL:String = "https://raw.githubusercontent.com/Maligan/Talon/master/browser/release/update.xml";
		public static function get APP_VERSION():String
		{
			var xml:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = xml.namespace();
			var version:String = xml.ns::versionNumber;
			return version;
		}

		public static const BROWSER_DOCUMENT_EXTENSION:String = "talon";
		public static const BROWSER_PUBLISH_EXTENSION:String = "zip";
		public static const BROWSER_PLUGIN_EXTENSION:String = "swf";
		public static const BROWSER_SCREENSHOT_EXTENSION:String = "png";
		public static const BROWSER_SUPPORTED_IMAGE_EXTENSIONS:Vector.<String> = new <String>["atf", "png", "jpg", "gif"];

		public static const PLUGINS_DIR:String = "plugins";
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
		public static const SETTING_DETACHED_PLUGINS:String = "detachedPlugins";

		//
		// Language
		//
		public static const T_OPEN_TITLE:String                             = "Open";
		public static const T_EXPORT_TITLE:String                           = "Export";
		public static const T_PROJECT_ROOT_TITLE:String                     = "Select Document root directory";
		public static const T_PROJECT_FILE_TITLE:String                     = "Select Document file";
		public static const T_PROJECT_FILE_DEFAULT_NAME:String              = "Untitled";
		public static const T_BROWSER_FILE_EXTENSION_NAME:String            = "Talon Designer Document";
		public static const T_BROWSER_EXPORT_FILE_EXTENSION_NAME:String     = "Zip Archive";
	}
}