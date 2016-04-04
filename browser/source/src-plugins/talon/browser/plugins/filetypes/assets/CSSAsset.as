package talon.browser.plugins.filetypes.assets
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

		override protected function activate():void
		{
			var source:String = readFileStringOrReport();
			if (source == null) return;

			if (isCSS(source) == true)
				document.factory.addStyleSheetWithId(file.url, source);
			else
				reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_CSS, file.url);
		}

		override protected function deactivate():void
		{
			document.factory.removeStyleSheetWithId(file.url);
		}
	}
}