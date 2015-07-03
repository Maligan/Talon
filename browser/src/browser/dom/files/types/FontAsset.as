package browser.dom.files.types
{
	import browser.dom.DocumentEvent;
	import browser.dom.log.DocumentMessage;

	import flash.system.System;

	import starling.events.Event;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.textures.Texture;

	public class FontAsset extends Asset
	{
		private var _xml:XML;
		private var _texture:Texture;
		private var _font:BitmapFont;

		override public function attach():void
		{
			_xml = readFileXMLOrReport();
			if (_xml) return;

			document.addEventListener(DocumentEvent.CHANGING, onDocumentChanging);
		}

		override public function detach():void
		{
			reportCleanup();

			_xml && System.disposeXML(_xml);
			_xml = null;

			_font && TextField.unregisterBitmapFont(_font.name, false);
			_font = null;

			document.removeEventListener(DocumentEvent.CHANGING, onDocumentChanging);

		}

		private function onDocumentChanging(e:Event):void
		{
			if (document.tasks.isBusy) return;

			var textureId:String = document.factory.getResourceId(_xml.pages.page.@file);
			var texture:Texture = document.factory.getResource(textureId);
			if (texture == null)
			{
				reportMessage(DocumentMessage.FONT_IMAGE_MISSED, file.url, textureId);
				return;
			}

			if (_texture != texture)
			{
				_texture = texture;
				_font = new BitmapFont(_texture, _xml);
				TextField.registerBitmapFont(_font);
			}
		}
	}
}