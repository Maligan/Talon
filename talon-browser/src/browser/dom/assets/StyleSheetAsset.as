package browser.dom.assets
{
	import browser.dom.log.DocumentMessage;
	import talon.StyleSheet;

	public class StyleSheetAsset extends Asset
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

		protected override function onRefresh():void
		{
			document.tasks.begin();

			clean();

			var source:String = file.readBytes().toString();

			if (isCSS(source) == true) document.factory.addStyleSheetWithId(file.url, source);
			else report(DocumentMessage.FILE_CSS_PARSE_ERROR, file.url);

			document.tasks.end();
		}

		protected override function onExclude():void
		{
			clean();
		}

		private function clean():void
		{
			reportCleanup();
			document.factory.removeStyleSheetWithId(file.url);
		}
	}
}