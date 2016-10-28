package talon.browser.desktop.utils
{
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;

	import talon.browser.platform.utils.Locale;

	use namespace flash_proxy;

	public class LocaleAdapter extends Proxy
	{
		private var _locale:Locale;

		public function LocaleAdapter(locale:Locale) { _locale = locale; }

		flash_proxy override function getProperty(name:*):* { return _locale.get(name); }
		flash_proxy override function hasProperty(name:*):Boolean { return true; }
	}
}
