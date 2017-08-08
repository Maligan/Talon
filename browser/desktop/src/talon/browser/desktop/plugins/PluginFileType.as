package talon.browser.desktop.plugins
{
	import starling.events.Event;

	import talon.browser.desktop.filetypes.CSSAsset;
	import talon.browser.desktop.filetypes.DirectoryAsset;
	import talon.browser.desktop.filetypes.PropertiesAsset;
	import talon.browser.desktop.filetypes.TextureAsset;
	import talon.browser.desktop.filetypes.XMLAtlasAsset;
	import talon.browser.desktop.filetypes.XMLFontAsset;
	import talon.browser.desktop.filetypes.XMLLibraryAsset;
	import talon.browser.desktop.filetypes.XMLMalformedAsset;
	import talon.browser.desktop.filetypes.XMLTemplateAsset;
	import talon.browser.desktop.utils.DesktopFileReference;
	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.plugins.IPlugin;
	import talon.utils.TalonFactoryBase;

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
				registerChecker(checkXMLMalformed,  XMLMalformedAsset);
			}
		}

		private function registerChecker(checker:Function, type:Class):void
		{
			_platform.document.files.registerController(checker, type);
		}

		//
		// Checkers
		//
		private function checkXMLTemplate(ref:DesktopFileReference):Boolean
		{
			return ref.checkFirstMeaningfulChar("<")
				&& ref.cacheXML
				&& ref.cacheXML.name()
				&& ref.cacheXML.name().toString() == TalonFactoryBase.TAG_TEMPLATE;
		}

		private function checkXMLLibrary(ref:DesktopFileReference):Boolean
		{
			return ref.checkFirstMeaningfulChar("<")
				&& ref.cacheXML
				&& ref.cacheXML.name()
				&& ref.cacheXML.name().toString() == TalonFactoryBase.TAG_LIBRARY;
		}

		private function checkXMLAtlas(ref:DesktopFileReference):Boolean
		{
			return ref.checkFirstMeaningfulChar("<")
				&& ref.cacheXML
				&& ref.cacheXML.name()
				&& ref.cacheXML.name().toString() == "TextureAtlas";
		}

		private function checkXMLFont(ref:DesktopFileReference):Boolean
		{
			if (ref.extension == "fnt") return true;

			return ref.checkFirstMeaningfulChar("<")
				&& ref.cacheXML
				&& ref.cacheXML.name() == "font";
		}

		private function checkXMLMalformed(ref:DesktopFileReference):Boolean
		{
			return ref.checkFirstMeaningfulChar("<")
				&& ref.cacheXML == null;
		}

		private function checkProperties(ref:DesktopFileReference):Boolean
		{
			return ref.extension == "properties";
		}

		private function checkDirectory(ref:DesktopFileReference):Boolean
		{
			return ref.target.isDirectory;
		}

		private function checkTexture(ref:DesktopFileReference):Boolean
		{
			return AppConstants.BROWSER_SUPPORTED_IMAGE_EXTENSIONS.indexOf(ref.extension) != -1;
		}

		private function checkCSS(ref:DesktopFileReference):Boolean
		{
			return ref.extension == "css";
		}
	}
}