package browser.dom.files.types
{
	import browser.dom.files.DocumentFileReference;
	import browser.dom.log.DocumentMessage;

	import talon.StyleSheet;

	public class StyleSheetAsset extends Asset
	{
		public static function checker(file:DocumentFileReference):Boolean
		{
			return file.extension == "css";
		}

		internal static function isCSS(css:String):Boolean
		{
			var style:StyleSheet = new StyleSheet();

			try
			{
				style.parse(css);
				return true;
			}
			catch (e:Error)
			{
				return false;
			}
		}

		public override function attach():void
		{
			var source:String = readFileStringOrReport();
			if (source == null) return;

			if (isCSS(source) == true)
				document.factory.addStyleSheetWithId(file.url, source);
			else
				reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_CSS, file.url);
		}

		public override function detach():void
		{
			reportCleanup();

			document.factory.removeStyleSheetWithId(file.url);
		}
	}
}