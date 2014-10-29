package starling.extension.talon.core
{
	public interface Layout
	{
		/** Вызывается при width = 'auto' */
		function measureWidth(ppp:Number, em:Number):int;
		/** Вызывается при height = 'auto' */
		function measureHeight(ppp:Number, em:Number):int;

		function arrange(ppp:Number, em:Number, width:int, height:int):void;
	}
}