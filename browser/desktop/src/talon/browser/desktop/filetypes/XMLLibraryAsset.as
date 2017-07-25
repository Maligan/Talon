package talon.browser.desktop.filetypes
{
	import flash.system.System;

	import talon.browser.platform.document.log.DocumentMessage;
	import talon.utils.ParseUtil;
	import talon.utils.TalonFactoryBase;

	public class XMLLibraryAsset extends Asset
	{
		private var _xml:XML;
		private var _css:Vector.<String> = new Vector.<String>();
		private var _templates:Vector.<String> = new Vector.<String>();
		private var _properties:Object = new Object();

		override protected function activate():void
		{
			_xml = readFileXMLOrReportAndNull();
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
						break;

					default:
						reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_ELEMENT, file.path, childType);
				}
			}
		}

		private function addTemplate(xml:XML):void
		{
			try
			{
				var templateId:String = xml.attribute(TalonFactoryBase.ATT_REF);
				document.factory.addTemplate(xml);
				_templates.push(templateId);
			}
			catch (e:ArgumentError)
			{
				reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_TEMPLATE, file.path, e.message);
			}
		}

		private function addCSS(style:String):void
		{
			var styleId:String = file.path + "#" + _css.length;

			if (CSSAsset.isCSS(style))
			{
				document.factory.addStyleSheetWithId(styleId, style);
				_css.push(styleId);
			}
			else
			{
				reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_CSS, file.path);
			}
		}

		private function addProperties(properties:String):void
		{
			ParseUtil.parseProperties(properties, _properties);
			document.factory.importResources(_properties);
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