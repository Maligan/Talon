package talon.browser.plugins.filetypes
{
	import talon.browser.plugins.filetypes.assets.CSSAsset;
	import talon.browser.plugins.filetypes.assets.DirectoryAsset;
	import talon.browser.plugins.filetypes.assets.PropertiesAsset;
	import talon.browser.plugins.filetypes.assets.TextureAsset;
	import talon.browser.plugins.filetypes.assets.XMLAtlasAsset;
	import talon.browser.plugins.filetypes.assets.XMLFontAsset;
	import talon.browser.plugins.filetypes.assets.XMLLibraryAsset;
	import talon.browser.plugins.filetypes.assets.XMLTemplateAsset;

	import starling.events.Event;

	import talon.browser.AppConstants;

	import talon.browser.AppPlatform;
	import talon.browser.AppPlatformEvent;
	import talon.browser.document.files.DocumentFileReference;
	import talon.browser.plugins.filetypes.assets.*;
	import talon.browser.plugins.IPlugin;
	import talon.utils.TalonFactory;

	public class PluginFileType implements IPlugin
	{
		private var _platform:AppPlatform;

		public function get id():String         { return "talon.browser.plugin.core.FileType"; }
		public function get version():String    { return "0.0.1"; }
		public function get versionAPI():String { return "0.1.0"; }

		public function attach(platform:AppPlatform):void
		{
			_platform = platform;
			_platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
		}

		public function detach():void
		{
			_platform.removeEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
			_platform = null;
		}

		private function onDocumentChange(e:Event):void
		{
			if (_platform.document != null)
			{
				registerChecker(checkProperties,    PropertiesAsset);
				registerChecker(checkDirectory,     DirectoryAsset);
				registerChecker(checkTexture,       TextureAsset);
				registerChecker(checkCSS,           CSSAsset);
				registerChecker(checkXMLTemplate,   XMLTemplateAsset);
				registerChecker(checkXMLLibrary,    XMLLibraryAsset);
				registerChecker(checkXMLAtlas,      XMLAtlasAsset);
				registerChecker(checkXMLFont,       XMLFontAsset);
			}
		}

		private function registerChecker(checker:Function, type:Class):void
		{
			_platform.document.files.registerController(checker, type);
		}

		//
		// Checkers
		//
		private function checkXMLTemplate(ref:DocumentFileReference):Boolean
		{
			return ref.checkFirstMeaningfulChar("<")
				&& ref.xml
				&& ref.xml.name()
				&& ref.xml.name().toString() == TalonFactory.TAG_TEMPLATE;
		}

		private function checkXMLLibrary(ref:DocumentFileReference):Boolean
		{
			return ref.checkFirstMeaningfulChar("<")
				&& ref.xml
				&& ref.xml.name()
				&& ref.xml.name().toString() == TalonFactory.TAG_LIBRARY;
		}

		private function checkXMLAtlas(ref:DocumentFileReference):Boolean
		{
			return ref.checkFirstMeaningfulChar("<")
				&& ref.xml
				&& ref.xml.name()
				&& ref.xml.name().toString() == "TextureAtlas";
		}

		private function checkXMLFont(ref:DocumentFileReference):Boolean
		{
			if (ref.extension == "fnt") return true;

			return ref.checkFirstMeaningfulChar("<")
				&& ref.xml
				&& ref.xml.name() == "font";
		}

		private function checkProperties(ref:DocumentFileReference):Boolean
		{
			return ref.extension == "properties";
		}

		private function checkDirectory(ref:DocumentFileReference):Boolean
		{
			return ref.target.isDirectory;
		}

		private function checkTexture(ref:DocumentFileReference):Boolean
		{
			return AppConstants.BROWSER_SUPPORTED_IMAGE_EXTENSIONS.indexOf(ref.extension) != -1;
		}

		private function checkCSS(ref:DocumentFileReference):Boolean
		{
			return ref.extension == "css";
		}
	}
}