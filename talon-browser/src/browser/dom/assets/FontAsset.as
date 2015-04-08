package browser.dom.assets
{
	import starling.events.Event;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.textures.Texture;

	public class FontAsset extends Asset
	{
		private var _fontXML:XML;
		private var _fontTexture:Texture;
		private var _font:BitmapFont;

		protected override function onInclude():void
		{
			document.addEventListener(Event.CHANGE, onDocumentChange);
		}

		protected override function onRefresh():void
		{
			validate(new XML(file.read()));
		}

		protected override function onExclude():void
		{
			if (_font)
			{
				document.tasks.begin();
				TextField.unregisterBitmapFont(fontName, true);
				document.tasks.end();
			}
		}

		private function onDocumentChange(e:Event):void
		{
			validate(_fontXML);
		}

		private function validate(xml:XML):void
		{
			var changed:Boolean = false;

			// XMl
			if (_fontXML != xml)
			{
				_fontXML = xml;
				changed = true;
			}

			// Texture
			var textureId:String = fontTextureId(xml);
			var texture:Texture = document.factory.getResource(textureId);

			if (_fontTexture != texture)
			{
				_fontTexture = texture;
				changed = true;
			}

			// Update font
			if (changed)
			{
				document.tasks.begin();

				if (_font != null)
				{
					TextField.unregisterBitmapFont(fontName, true);
					_font = null;
				}

				if (_fontTexture != null)
				{
					_font = new BitmapFont(_fontTexture, _fontXML);
					TextField.registerBitmapFont(_font, fontName);
				}

				document.tasks.end();
			}
		}

		private function get fontName():String
		{
			return document.factory.getResourceId(file.url);
		}

		private function fontTextureId(xml:XML):String
		{
			return document.factory.getResourceId(xml.pages.page.@file.toString());
		}
	}
}