package browser.dom.assets
{
	public class StyleSheetAsset extends Asset
	{
		protected override function onRefresh():void
		{
			document.tasks.begin();
			document.factory.addStyleSheet(file.readBytes().toString());
			document.tasks.end();
		}
	}
}