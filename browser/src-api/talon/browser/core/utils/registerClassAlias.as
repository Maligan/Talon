package talon.browser.core.utils
{
	import avmplus.getQualifiedClassName;
	import flash.net.registerClassAlias;

	public function registerClassAlias(classObject:Class, classAlias:String = null):void
	{
		classAlias ||= getQualifiedClassName(classObject);
		flash.net.registerClassAlias(classAlias, classObject);
	}
}
