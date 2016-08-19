package talon.utils
{
	public function getMemoryAddress(object:Object):String
	{
		if (getMemoryAddressCache[object] == null)
		{
			try { getMemoryAddressFakeClass(object); }
			catch (e:Error) { getMemoryAddressCache[object] = String(e).replace(/.*([@|\$].*?) to .*$/gi, '$1'); }
		}

		return getMemoryAddressCache[object];
	}
}

import flash.utils.Dictionary;
const getMemoryAddressCache:Dictionary = new Dictionary(true);
final class getMemoryAddressFakeClass { }