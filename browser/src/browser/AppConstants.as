package browser
{
	public class AppConstants
	{
		public static const APP_NAME:String = "Talon Browser";
		public static const APP_VERSION:String = "0.0.1";

		public static const DESIGNER_FILE_EXTENSION:String = "talon";
		public static const DESIGNER_EXPORT_FILE_EXTENSION:String = "zip";
		public static const SUPPORTED_IMAGE_EXTENSIONS:Vector.<String> = new <String>["atf", "png", "jpg", "gif"];

		public static const PROPERTY_SOURCE_PATH:String     = "source.path";
		public static const PROPERTY_EXPORT_IGNORE:String   = "export.ignore";
		public static const PROPERTY_EXPORT_PATH:String     = "export.path";

		public static const SETTING_BACKGROUND:String = "background";
		public static const SETTING_BACKGROUND_CHESS:String = "transparent";
		public static const SETTING_BACKGROUND_DARK:String = "dark";
		public static const SETTING_BACKGROUND_LIGHT:String = "light";
		public static const SETTING_BACKGROUND_DEFAULT:String = SETTING_BACKGROUND_DARK;
		public static const SETTING_STATS:String = "stats";
		public static const SETTING_ZOOM:String = "zoom";
		public static const SETTING_LOCK_RESIZE:String = "lockWindowResize";
		public static const SETTING_RECENT_ARRAY:String = "recent";
		public static const SETTING_PROFILE:String = "profile";
		public static const SETTING_IS_PORTRAIT:String = "isPortrait";

		public static const ZOOM_MIN:int = 25;
		public static const ZOOM_MAX:int = 300;
		public static const HISTORY_RECENT_MAX:int = 10;

		public static const T_EXPORT_TITLE:String = "Export";
		public static const T_PROJECT_ROOT_TITLE:String = "Select project root directory";
		public static const T_PROJECT_FILE_TITLE:String = "Select project file";
		public static const T_PROJECT_FILE_DEFAULT_NAME:String = "Untitled";
		public static const T_DESIGNER_FILE_EXTENSION_NAME:String = "Talon Designer Project";
		public static const T_DESIGNER_EXPORT_FILE_EXTENSION_NAME:String = "Zip Archive";
		public static const T_MENU_FILE:String = "File";
		public static const T_MENU_FILE_OPEN:String = "Open...";
		public static const T_MENU_FILE_NEW_PROJECT:String = "New Project...";
		public static const T_MENU_FILE_RECENT:String = "Open Recent";
		public static const T_MENU_FILE_RECENT_CLEAR:String = "Clear";
		public static const T_MENU_FILE_EXPORT_AS:String = "Export As...";
		public static const T_MENU_FILE_CLOSE:String = "Close";
		public static const T_MENU_NAVIGATE:String = "Navigate";
		public static const T_MENU_NAVIGATE_SEARCH:String = "Search...";
		public static const T_MENU_VIEW:String = "View";
		public static const T_MENU_VIEW_BACKGROUND:String = "Background";
		public static const T_MENU_VIEW_BACKGROUND_LIGHT:String = "Light";
		public static const T_MENU_VIEW_BACKGROUND_DARK:String = "Dark";
		public static const T_MENU_VIEW_BACKGROUND_CHESS:String = "Transparent";
		public static const T_MENU_VIEW_STATS:String = "Show Stats";
		public static const T_MENU_VIEW_LOCK_RESIZE:String = "Lock Window Size";
		public static const T_MENU_VIEW_ZOOM_IN:String = "Zoom In";
		public static const T_MENU_VIEW_ZOOM_OUT:String = "Zoom Out";
		public static const T_MENU_VIEW_ORIENTATION:String = "Orientation";
		public static const T_MENU_VIEW_ORIENTATION_PORTRAIT:String = "Portrait";
		public static const T_MENU_VIEW_ORIENTATION_LANDSCAPE:String = "Landscape";
		public static const T_MENU_VIEW_PROFILE:String = "Profile";
		public static const T_MENU_VIEW_PROFILE_CUSTOM:String = "Custom...";
		public static const T_MENU_VIEW_CONSOLE:String = "Console";
		public static const T_MENU_HELP:String = "Help";
		public static const T_MENU_HELP_ONLINE:String = "Online Documentation";
		public static const T_MENU_HELP_ABOUT:String = "About";
	}
}