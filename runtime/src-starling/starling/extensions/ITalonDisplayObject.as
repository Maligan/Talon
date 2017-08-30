package starling.extensions
{
	import talon.core.Node;

	public interface ITalonDisplayObject
	{
		function query(selector:String = null):TalonQuery;
		
		function get node():Node

		/** DEPRECATED */
		function get manual():Boolean
		function set manual(value:Boolean):void
	}
}