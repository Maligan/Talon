package talon.browser.desktop.filetypes
{
	import talon.utils.ParseUtil;

	public class PropertiesAsset extends Asset
	{
		private var _properties:Object;

		override protected function activate():void
		{
			var string:String = readFileStringOrReport();
			if (string == null) return;

			_properties = ParseUtil.parseProperties(string);

			document.factory.appendResources(_properties);
		}

		override protected function deactivate():void
		{
            if (_properties)
				document.factory.removeResources(_properties);

            _properties = null;
		}
	}
}