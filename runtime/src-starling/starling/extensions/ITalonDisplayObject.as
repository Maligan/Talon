package starling.extensions
{
	import flash.geom.Rectangle;

	import talon.core.Node;
	import talon.core.Style;

	public interface ITalonDisplayObject
	{
		/** Select elements from display tree.
		 *  In case <code>selector</code> equals null, simple wrap current object with query.
		 *  @param CSS selector supported by Talon.
		 */
		function query(selector:String = null):TalonQuery;

		// TODO: Next public API
		// + validate()	- For implicit control validation process
		// + clone()	- For easy copy/paste

		function getAttribute(name:String):String;
		function setAttribute(name:String, value:String):void;
		function setResources(resources:Object):void;
		function setStyles(styles:Vector.<Style>):void;

		/** Bounds rectangle in parent coordinate system. */
		function get rectangle():Rectangle;

		/** @private For internal usage (in public API use delegating to node methods) */
		function get node():Node
	}
}