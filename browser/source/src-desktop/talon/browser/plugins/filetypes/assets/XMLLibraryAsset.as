package talon.browser.plugins.filetypes.assets
{
	import talon.browser.plugins.filetypes.assets.*;
	import flash.system.System;

	import talon.browser.document.log.DocumentMessage;
	import talon.utils.StringParseUtil;
	import talon.utils.TalonFactoryBase;

	public class XMLLibraryAsset extends Asset
	{
		private var _xml:XML;
		private var _css:Vector.<String> = new Vector.<String>();
		private var _templates:Vector.<String> = new Vector.<String>();
		private var _properties:Object = new Object();

		override protected function activate():void
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

					case TalonFactoryBase.TAG_PROPERTIES:
						addProperties(child.text());

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

		private function addProperties(properties:String):void
		{
			StringParseUtil.parseProperties(properties, _properties);
			document.factory.addResourcesFromObject(_properties);
		}

		override protected function deactivate():void
		{
			_xml && System.disposeXML(_xml);
			_xml = null;

			while (_css.length)
				document.factory.removeStyleSheetWithId(_css.pop());

			while (_templates.length)
				document.factory.removeTemplate(_templates.pop());

			for (var property:String in _properties)
				document.factory.removeResource(property);

			_properties = {};
		}
	}
}