package designer.dom.assets
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.utils.ByteArray;

	import starling.textures.AtfData;
	import starling.textures.Texture;

	public class TextureAsset extends Asset
	{
		protected override function onRefresh():void
		{
			var bytes:ByteArray = file.read();

			if (AtfData.isAtfData(bytes))
			{
				document.tasks.begin();
				document.factory.addResource(document.factory.getResourceId(file.url), Texture.fromAtfData(bytes));
				document.tasks.end();
			}
			else
			{
				document.tasks.begin();
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
				loader.loadBytes(bytes);

				function onComplete(e:*):void
				{
					document.factory.addResource(document.factory.getResourceId(file.url), Texture.fromBitmap(loader.content as Bitmap));
					document.tasks.end();
				}
			}
		}

		protected override function onExclude():void
		{
			document.tasks.begin();
			document.factory.removeResource(document.factory.getResourceId(file.url));
			document.tasks.end();
		}
	}
}
