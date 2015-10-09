package talon.browser.plugins.tools.types
{
	import talon.StyleSheet;
	import talon.browser.document.log.DocumentMessage;

	public class CSSAsset extends Asset
	{
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