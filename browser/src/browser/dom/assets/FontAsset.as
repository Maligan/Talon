package browser.dom.assets
{
	import browser.dom.DocumentEvent;
	import browser.dom.log.DocumentMessage;

	import starling.events.Event;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.textures.Texture;

	public class FontAsset extends Asset
	{
		private var _lastXML:XML;
		private var _lastTexture:Texture;
		private var _lastFont:BitmapFont;

		protected override function onInclude():void { document.addEventListener(DocumentEvent.CHANGING, onDocumentChanging); }
		protected override function onExclude():void
		{
			document.tasks.begin();
			document.removeEventListener(DocumentEvent.CHANGING, onDocumentChanging);
			clean();
			document.tasks.end();
		}

		protected override function onRefresh():void
		{
			document.tasks.begin();

			clean();
			_lastXML = file.readXML();
			document.tasks.end();
		}

		private function onDocumentChanging(e:Event):void
		{
			if (_lastXML == null) return;
			if (document.tasks.isBusy) return;

			var textureId:String = document.factory.getResourceId(_lastXML.pages.page.@file);
			var texture:Texture = document.factory.getResource(textureId);

			if (texture == null)
			{
				file.report(DocumentMessage.FONT_IMAGE_MISSED, file.url, textureId);
				return;
			}

			if (_lastFont == null || _lastTexture != texture)
			{
				document.tasks.begin();

				file.reportCleanup();
				_lastTexture = texture;
				_lastFont = new BitmapFont(_lastTexture, _lastXML);
				TextField.registerBitmapFont(_lastFont, textureId);
				trace("[FontAsset]", "registerBitmapFont", _lastFont.name);

				document.tasks.end();
			}
		}

		private function clean():void
		{
			file.reportCleanup();

			if (_lastFont)
			{
				TextField.unregisterBitmapFont(_lastFont.name, false);
				_lastFont = null;
			}
		}
	}
}