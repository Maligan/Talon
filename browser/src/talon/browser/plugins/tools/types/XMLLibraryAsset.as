package talon.browser.plugins.tools.types
{
	import talon.browser.document.files.DocumentFileReference;
	import talon.browser.document.log.DocumentMessage;

	import flash.system.System;

	import talon.utils.TalonFactoryBase;

	public class XMLLibraryAsset extends Asset
	{
		private var _xml:XML;
		private var _css:Vector.<String> = new Vector.<String>();
		private var _templates:Vector.<String> = new Vector.<String>();

		public override function attach():void
		{
			_xml = readFileXMLOrReport();
			if (_xml == null) return;

			for each (var child:XML in _xml.children())
			{
				var childType:String = child.name();

				switch (childType)
				{
					case TalonFactoryBase.TAG_STYLE:
						addCSS(child.text());
						break;

					case TalonFactoryBase.TAG_TEMPLATE:
						addTemplate(child);
						break;

					default:
						reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_ELEMENT, file.url, childType);
				}
			}
		}

		private function addTemplate(xml:XML):void
		{
			try
			{
				var templateId:String = xml.@id;
				document.factory.addTemplate(xml);
				_templates.push(templateId);
			}
			catch (e:ArgumentError)
			{
				reportMessage(DocumentMessage.TEMPLATE_ERROR, file.url, e.message);
			}
		}

		private function addCSS(style:String):void
		{
			var styleId:String = file.url + "#" + _css.length;

			if (CSSAsset.isCSS(style))
			{
				document.factory.addStyleSheetWithId(styleId, style);
				_css.push(styleId);
			}
			else
			{
				reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_CSS, file.url);
			}
		}

		public override function detach():void
		{
			reportCleanup();

			_xml && System.disposeXML(_xml);
			_xml = null;

			while (_css.length)
				document.factory.removeStyleSheetWithId(_css.pop());

			while (_templates.length)
				document.factory.removeTemplate(_templates.pop());
		}
	}
}