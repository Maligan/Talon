package talon.browser.plugins.tools
{
	import starling.events.Event;

	import talon.browser.AppConstants;

	import talon.browser.AppController;
	import talon.browser.document.files.DocumentFileReference;
	import talon.browser.plugins.tools.types.*;
	import talon.browser.plugins.IPlugin;
	import talon.utils.TalonFactoryBase;

	public class FileTypePlugin implements IPlugin
	{
		private var _app:AppController;

		public function get id():String         { return "talon.browser.tools.FileType"; }
		public function get version():String    { return "0.0.1"; }
		public function get versionAPI():String { return "0.1.0"; }

		public function attach(app:AppController):void
		{
			_app = app;
			_app.addEventListener(AppController.EVENT_DOCUMENT_CHANGE, onDocumentChange);
		}

		public function detach():void
		{
			_app.removeEventListener(AppController.EVENT_DOCUMENT_CHANGE, onDocumentChange);
			_app = null;
		}

		private function onDocumentChange(e:Event):void
		{
			if (_app.document != null)
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
			_app.document.files.registerController(type, checker);
		}

		//
		// Checkers
		//
		private function checkXMLTemplate(ref:DocumentFileReference):Boolean
		{
			return ref.checkFirstMeaningfulChar("<")
				&& ref.xml
				&& ref.xml.name().toString() == TalonFactoryBase.TAG_TEMPLATE;
		}

		private function checkXMLLibrary(ref:DocumentFileReference):Boolean
		{
			return ref.checkFirstMeaningfulChar("<")
				&& ref.xml
				&& ref.xml.name().toString() == TalonFactoryBase.TAG_LIBRARY;
		}

		private function checkXMLAtlas(ref:DocumentFileReference):Boolean
		{
			return ref.checkFirstMeaningfulChar("<")
				&& ref.xml
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