package talon.browser.desktop.filetypes
{
	import flash.system.System;

	import starling.events.Event;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	import talon.browser.platform.document.DocumentEvent;
	import talon.browser.platform.document.log.DocumentMessage;

	public class XMLAtlasAsset extends Asset
	{
		private var _xml:XML;
		private var _texture:Texture;
		private var _atlas:TextureAtlas;
		private var _resources:Object;

		override protected function activate():void
		{
			_xml = readFileXMLOrReportAndNull();
			if (_xml == null) return;

			document.addEventListener(DocumentEvent.CHANGING, onDocumentChanging);
			onDocumentChanging(null);
		}

		override protected function deactivate():void
		{
			_texture = null;

			_xml && System.disposeXML(_xml);
			_xml = null;

			if (_resources)
			{
				document.factory.removeResources(_resources);
				_resources = null;
			}
			
			if (_atlas)
			{
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
				reportMessage(DocumentMessage.TEXTURE_MISS_ATLAS, file.path, textureId);
				return;
			}

			if (_texture != texture)
			{
				_resources = {};
				_texture = texture;
				_atlas = new TextureAtlas(_texture, _xml);

				for each (textureId in _atlas.getNames())
					_resources[textureId] = _atlas.getTexture(textureId);
				
				document.factory.appendResources(_resources);
			}
		}
	}
}