package talon.browser.core
{
	import flash.utils.getDefinitionByName;

	public class AppConstants
	{
		public static const APP_NAME:String = "Talon Browser";
		public static const APP_DOCUMENTATION_URL:String = "https://github.com/Maligan/Talon/blob/master/docs/index.md";
		public static const APP_TRACKER_URL:String = "https://github.com/Maligan/Talon/issues";

		public static function get APP_VERSION_LABEL():String { return readDescriptor("versionLabel") }
		public static function get APP_VERSION():String { return readDescriptor("versionNumber") }
		
		private static function readDescriptor(key:String):String
		{
			try
			{
				var napp:Class = getDefinitionByName("flash.desktop.NativeApplication") as Class;
				var xml:XML = napp["nativeApplication"]["applicationDescriptor"];
				var ns:Namespace = xml.namespace();
				return xml.ns::[key];
			}
			catch (e:Error)
			{
				return "";
			}
		}

		public static const PLUGINS_DIR:String = "plugins";

		public static const BROWSER_DOCUMENT_FILENAME:String = ".talon";
		public static const BROWSER_PLUGIN_EXTENSION:String = "swf";
		public static const BROWSER_SCREENSHOT_EXTENSION:String = "png";
		public static const BROWSER_SUPPORTED_IMAGE_EXTENSIONS:Vector.<String> = new <String>["atf", "png", "jpg", "gif"];

		public static const PUBLISH_EXTENSION:String = "zip";
		public static const PUBLISH_CACHE_FILENAME:String = "talon.json";
		public static const PUBLISH_FONTS_PREFIX:String = "fonts/";
		public static const PUBLISH_SPRITES_PREFIX:String = "sprites/";

		public static const ZOOM_MIN:Number = 0.25;
		public static const ZOOM_MAX:Number = 3.00;
		public static const RECENT_HISTORY:int = 10;

		public static const SETTING_BACKGROUND:String = "background";
		public static const SETTING_BACKGROUND_COLOR:String = "backgroundColor";
		public static const SETTING_BACKGROUNDS:Array = [
			{ name: "Dark",  texture: "bg_dark",  color: 0x3F4142 },
			{ name: "Light", texture: "bg_light", color: 0xBFBFBF }
		];

		public static const SETTING_ZOOM:String = "zoom";
		public static const SETTING_STATS:String = "showStats";
		public static const SETTING_SHOW_OUTLINE:String = "showOutline";
		public static const SETTING_SHOW_INSPECTOR:String = "showInspector";
		public static const SETTING_ALWAYS_ON_TOP:String = "alwaysOnTop";
		public static const SETTING_AUTO_REOPEN:String = "autoReopen";
		public static const SETTING_RECENT_DOCUMENTS:String = "recentDocuments";
		public static const SETTING_RECENT_TEMPLATE:String = "recentTemplate";
		public static const SETTING_PROFILE:String = "profile";
		public static const SETTING_PROFILE_BIND_MODE:String = "profileBindMode";
		public static const SETTING_CHECK_FOR_UPDATE_ON_STARTUP:String = "checkForUpdateOnStartup";
		public static const SETTING_WINDOW_SIZE:String = "windowSize";
		public static const SETTING_WINDOW_SIZE_LOCK:String = "windowSizeLock";
		public static const SETTING_DETACHED_PLUGINS:String = "detachedPlugins";
		public static const SETTING_TEXTURE_PACKER_BIN:String = "texturePackerBin";

		//
		// Language
		//
		public static const T_OPEN_TITLE:String                             = "Open Document Root Folder";
		public static const T_EXPORT_TITLE:String                           = "Export";
		public static const T_SELECT_TEXTURE_PACKER:String                  = "Select TexturePacker CLI";
		public static const T_SCREENSHOT_TITLE:String                       = "Select Screenshot File";
		public static const T_PROJECT_ROOT_TITLE:String                     = "Select Document Folder";
	}
}
