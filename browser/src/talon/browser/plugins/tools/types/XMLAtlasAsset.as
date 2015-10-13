package talon.browser.plugins.tools.types
{
	import flash.system.System;

	import starling.events.Event;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	import talon.browser.document.DocumentEvent;
	import talon.browser.document.log.DocumentMessage;

	public class XMLAtlasAsset extends Asset
	{
		private var _xml:XML;
		private var _texture:Texture;
		private var _atlas:TextureAtlas;

		override protected function activate():void
		{
			_xml = readFileXMLOrReport();
			if (_xml == null) return;

			document.addEventListener(DocumentEvent.CHANGING, onDocumentChanging);
			onDocumentChanging(null);
		}

		override protected function deactivate():void
		{
			_texture = null;

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

			document.removeEventListener(DocumentEvent.CHANGING, onDocumentChanging);
		}

		private function onDocumentChanging(e:Event):void
		{
			if (document.tasks.isBusy) return;
			reportCleanup();

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