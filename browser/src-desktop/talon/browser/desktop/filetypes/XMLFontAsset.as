package talon.browser.desktop.filetypes
{
	import flash.system.System;

	import starling.events.Event;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.textures.Texture;

	import talon.browser.core.document.DocumentEvent;
	import talon.browser.core.document.log.DocumentMessage;

	public class XMLFontAsset extends Asset
	{
		private var _xml:XML;
		private var _texture:Texture;
		private var _font:BitmapFont;

		override protected function activate():void
		{
			_xml = readFileXMLOrReportAndNull();
			if (_xml == null) return;

			document.addEventListener(DocumentEvent.CHANGING, onDocumentChanging);
			onDocumentChanging(null);
		}

		override protected function deactivate():void
		{
			_xml && System.disposeXML(_xml);
			_xml = null;

			_font && TextField.unregisterCompositor(_font.name, false);
			_font = null;

			_texture = null;

			document.removeEventListener(DocumentEvent.CHANGING, onDocumentChanging);
		}

		private function onDocumentChanging(e:Event):void
		{
			if (document.tasks.isBusy) return;
			reportCleanup();

			var textureId:String = document.factory.getResourceId(_xml.pages.page.@file);
			var texture:Texture = document.factory.getResource(textureId);
			if (texture == null)
			{
				reportMessage(DocumentMessage.TEXTURE_MISS_FONT, file.path, textureId);
				return;
			}

			if (_texture != texture)
			{
				document.tasks.begin();
				_texture = texture;
				_font = new BitmapFont(_texture, _xml);
				TextField.registerCompositor(_font, _font.name);
				document.tasks.end();
			}
		}
	}
}