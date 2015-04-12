package browser.dom.assets
{
	import browser.dom.DocumentEvent;
	import browser.dom.log.DocumentMessage;

	import flash.system.System;

	import starling.events.Event;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	public class AtlasAsset extends Asset
	{
		private var _lastXML:XML;
		private var _lastTexture:Texture;
		private var _lastAtlas:TextureAtlas;

		protected override function onInclude():void { document.addEventListener(DocumentEvent.CHANGING, onDocumentChanging); }
		protected override function onExclude():void
		{
			document.removeEventListener(DocumentEvent.CHANGING, onDocumentChanging);
			clean();
		}

		protected override function onRefresh():void
		{
			document.tasks.begin();

			clean();

			_lastXML = file.readXML();
			if (_lastXML == null) report(DocumentMessage.FILE_XML_PARSE_ERROR, file.url);

			document.tasks.end();
		}

		private function onDocumentChanging(e:Event):void
		{
			if (_lastXML == null) return;
			if (document.tasks.isBusy) return;

			var textureId:String = document.factory.getResourceId(_lastXML.@imagePath);
			var texture:Texture = document.factory.getResource(textureId);
			if (texture == null)
			{
				report(DocumentMessage.ATLAS_IMAGE_NOT_FOUND, file.url, textureId);
				return;
			}

			if (_lastAtlas == null || _lastTexture != texture)
			{
				document.tasks.begin();

				_lastTexture = texture;
				_lastAtlas = new TextureAtlas(_lastTexture, _lastXML);

				for each (var textureId:String in _lastAtlas.getNames())
				{
					var texture:Texture = _lastAtlas.getTexture(textureId);
					document.factory.addResource(textureId, texture);
				}

				document.tasks.end();
			}
		}

		private function clean():void
		{
			reportCleanup();

			System.disposeXML(_lastXML);
			_lastXML = null;

			if (_lastAtlas)
			{
				for each (var textureId:String in _lastAtlas.getNames())
					document.factory.removeResource(textureId)

//				_lastAtlas.dispose();
				_lastAtlas = null;
			}
		}
	}
}