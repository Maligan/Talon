package starling.extensions
{
	import talon.Node;

	public interface ITalonElement
	{
		function query(selector:String = null):TalonQuery;

		function get node():Node

		/** DEPRECATED */
		function get manual():Boolean
		function set manual(value:Boolean):void
	}
}