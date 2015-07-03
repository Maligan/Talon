package browser.dom.files.types
{
	import browser.dom.DocumentEvent;
	import browser.dom.log.DocumentMessage;

	import flash.system.System;

	import starling.events.Event;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	public class AtlasAsset extends Asset
	{
		private var _xml:XML;
		private var _texture:Texture;
		private var _atlas:TextureAtlas;

		public override function attach():void
		{
			_xml = readFileXMLOrReport();
			if (_xml == null) return;

			document.addEventListener(DocumentEvent.CHANGING, onDocumentChanging);
		}

		public override function detach():void
		{
			reportCleanup();
			document.removeEventListener(DocumentEvent.CHANGING, onDocumentChanging);

			_texture = null; // NB! Do not dispose()

			_xml && System.disposeXML(_xml);
			_xml = null;

			if (_atlas)
			{
				var names:Vector.<String> = _atlas.getNames();

				while (names.length)
					document.factory.removeResource(names.pop());

				_atlas.dispose();
				_atlas = null;
			}
		}

		private function onDocumentChanging(e:Event):void
		{
			if (document.tasks.isBusy) return;

			var textureId:String = document.factory.getResourceId(_xml.@imagePath);
			var texture:Texture = document.factory.getResource(textureId);
			if (texture == null)
			{
				reportMessage(DocumentMessage.ATLAS_IMAGE_MISSED, file.url, textureId);
				return;
			}

			if (_texture != texture)
			{
				_texture = texture;
				_atlas = new TextureAtlas(_texture, _xml);

				for each (textureId in _atlas.getNames())
				{
					texture = _atlas.getTexture(textureId);
					document.factory.addResource(textureId, texture);
				}
			}
		}
	}
}