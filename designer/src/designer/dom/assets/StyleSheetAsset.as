package designer.dom.assets
{
	public class StyleSheetAsset extends Asset
	{
		protected override function onRefresh():void
		{
			document.tasks.begin();
			document.factory.addStyleSheet(file.read().toString());
			document.tasks.end();
		}
	}
}