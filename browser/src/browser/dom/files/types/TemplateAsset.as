package browser.dom.files.types
{
	import browser.dom.files.DocumentFileReference;
	import browser.dom.log.DocumentMessage;

	import flash.system.System;

	import talon.utils.TalonFactoryBase;

	public class TemplateAsset extends Asset
	{
		public static function checker(file:DocumentFileReference):Boolean
		{
			return file.checkFirstMeaningfulChar("<")
				&& file.xml
				&& file.xml.name().toString() == TalonFactoryBase.TAG_TEMPLATE;
		}

		private var _id:String;
		private var _xml:XML;

		public override function attach():void
		{
			_xml = readFileXMLOrReport();
			if (_xml == null) return;

			try
			{
				document.factory.addTemplate(_xml);
				_id = _xml.@id;
			}
			catch (e:ArgumentError)
			{
				reportMessage(DocumentMessage.TEMPLATE_ERROR, file.url, e.message);
			}
		}

		public override function detach():void
		{
			reportCleanup();

			document.factory.removeTemplate(_id);
			_id = null;

			_xml && System.disposeXML(_xml);
			_xml = null;
		}
	}
}