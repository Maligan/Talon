package browser.document.files.types
{
	import browser.document.DocumentEvent;
	import browser.document.files.DocumentFileReference;
	import browser.document.log.DocumentMessage;

	import flash.system.System;

	import starling.events.Event;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.textures.Texture;

	public class FontAsset extends Asset
	{
		public static function checker(file:DocumentFileReference):Boolean
		{
			return file.extension == "fnt"
				|| (file.checkFirstMeaningfulChar("<") && file.xml && file.xml.name() == "font");
		}

		private var _xml:XML;
		private var _texture:Texture;
		private var _font:BitmapFont;

		override public function attach():void
		{
			_xml = readFileXMLOrReport();
			if (_xml == null) return;

			document.addEventListener(DocumentEvent.CHANGING, onDocumentChanging);
			onDocumentChanging(null);
		}

		override public function detach():void
		{
			reportCleanup();

			_xml && System.disposeXML(_xml);
			_xml = null;

			_font && TextField.unregisterBitmapFont(_font.name, false);
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
				reportMessage(DocumentMessage.FONT_IMAGE_MISSED, file.url, textureId);
				return;
			}

			if (_texture != texture)
			{
				document.tasks.begin();
				_texture = texture;
				_font = new BitmapFont(_texture, _xml);
				TextField.registerBitmapFont(_font);
				document.tasks.end();
			}
		}
	}
}